#include "skynet_malloc.h"

#include "skynet_socket.h"

#include <lua.h>
#include <lauxlib.h>

#include <assert.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#define QUEUESIZE 1024
#define HASHSIZE 4096
#define SMALLSTRING 2048

#define TYPE_DATA 1
#define TYPE_MORE 2
#define TYPE_ERROR 3
#define TYPE_OPEN 4
#define TYPE_CLOSE 5

/* -------------------------pack func ----------------------------------------- */

/*
	Each package is raw data .
 */

static int
filter_data_(lua_State *L, int fd, uint8_t * buffer, int size) {
	int pack_size = size;
	
	lua_pushvalue(L, lua_upvalueindex(TYPE_DATA));
	lua_pushinteger(L, fd);
	void * result = skynet_malloc(pack_size);
	memcpy(result, buffer, size);
	lua_pushlightuserdata(L, result);
	lua_pushinteger(L, size);
	return 5;
}


static inline int
filter_data(lua_State *L, int fd, uint8_t * buffer, int size) {
	int ret = filter_data_(L, fd, buffer, size);
	// buffer is the data of socket message, it malloc at socket_server.c : function forward_message .
	// it should be free before return,
	skynet_free(buffer);
	return ret;
}

static void
pushstring(lua_State *L, const char * msg, int size) {
	if (msg) {
		lua_pushlstring(L, msg, size);
	} else {
		lua_pushliteral(L, "");
	}
}

/*
	userdata queue
	lightuserdata msg
	integer size
	return
		userdata queue
		integer type
		integer fd
		string msg | lightuserdata/integer
 */
static int
lfilter(lua_State *L) {
	struct skynet_socket_message *message = lua_touserdata(L,2);
	int size = luaL_checkinteger(L,3);
	char * buffer = message->buffer;
	if (buffer == NULL) {
		buffer = (char *)(message+1);
		size -= sizeof(*message);
	} else {
		size = -1;
	}

	lua_settop(L, 1);

	switch(message->type) {
	case SKYNET_SOCKET_TYPE_DATA:
		// ignore listen id (message->id)
		assert(size == -1);	// never padding string
		return filter_data(L, message->id, (uint8_t *)buffer, message->ud);
	case SKYNET_SOCKET_TYPE_CONNECT:
		// ignore listen fd connect
		return 1;
	case SKYNET_SOCKET_TYPE_CLOSE:
		lua_pushvalue(L, lua_upvalueindex(TYPE_CLOSE));
		lua_pushinteger(L, message->id);
		return 3;
	case SKYNET_SOCKET_TYPE_ACCEPT:
		lua_pushvalue(L, lua_upvalueindex(TYPE_OPEN));
		// ignore listen id (message->id);
		lua_pushinteger(L, message->ud);
		pushstring(L, buffer, size);
		return 4;
	case SKYNET_SOCKET_TYPE_ERROR:
		lua_pushvalue(L, lua_upvalueindex(TYPE_ERROR));
		lua_pushinteger(L, message->id);
		pushstring(L, buffer, size);
		return 4;
	default:
		// never get here
		return 1;
	}
}

static const char *
tolstring(lua_State *L, size_t *sz) {
	const char * ptr;
	if (lua_isuserdata(L,1)) {
		ptr = (const char *)lua_touserdata(L,1);
		*sz = (size_t)luaL_checkinteger(L, 2);
	} else {
		ptr = luaL_checklstring(L, 1, sz);
	}
	return ptr;
}

static int
lpack(lua_State *L) {
	size_t len;
	const char * ptr = tolstring(L, &len);
	if (len > 0x10000) {
		return luaL_error(L, "Invalid size (too long) of data : %d", (int)len);
	}

	uint8_t * buffer = skynet_malloc(len+1);
	memcpy(buffer, ptr, len);
	buffer[len]='\n';
	lua_pushlightuserdata(L, buffer);
	lua_pushinteger(L, len+1);

	return 2;
}

/* -------------------------pack func end----------------------------------------- */

/* -------------------------mine func ----------------------------------------- */

typedef unsigned char UC;
static const char CRLF[] = "\r\n";
static const char EQCRLF[] = "=\r\n";

static const UC b64base[] =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
static UC b64unbase[256];

/*-------------------------------------------------------------------------*\
* Acumulates bytes in input buffer until 3 bytes are available. 
* Translate the 3 bytes into Base64 form and append to buffer.
* Returns new number of bytes in buffer.
\*-------------------------------------------------------------------------*/
static size_t b64encode(UC c, UC *input, size_t size, 
        luaL_Buffer *buffer)
{
    input[size++] = c;
    if (size == 3) {
        UC code[4];
        unsigned long value = 0;
        value += input[0]; value <<= 8;
        value += input[1]; value <<= 8;
        value += input[2]; 
        code[3] = b64base[value & 0x3f]; value >>= 6;
        code[2] = b64base[value & 0x3f]; value >>= 6;
        code[1] = b64base[value & 0x3f]; value >>= 6;
        code[0] = b64base[value];
        luaL_addlstring(buffer, (char *) code, 4);
        size = 0;
    }
    return size;
}

/*-------------------------------------------------------------------------*\
* Encodes the Base64 last 1 or 2 bytes and adds padding '=' 
* Result, if any, is appended to buffer.
* Returns 0.
\*-------------------------------------------------------------------------*/
static size_t b64pad(const UC *input, size_t size, 
        luaL_Buffer *buffer)
{
    unsigned long value = 0;
    UC code[4] = {'=', '=', '=', '='};
    switch (size) {
        case 1:
            value = input[0] << 4;
            code[1] = b64base[value & 0x3f]; value >>= 6;
            code[0] = b64base[value];
            luaL_addlstring(buffer, (char *) code, 4);
            break;
        case 2:
            value = input[0]; value <<= 8; 
            value |= input[1]; value <<= 2;
            code[2] = b64base[value & 0x3f]; value >>= 6;
            code[1] = b64base[value & 0x3f]; value >>= 6;
            code[0] = b64base[value];
            luaL_addlstring(buffer, (char *) code, 4);
            break;
        default:
            break;
    }
    return 0;
}

/*-------------------------------------------------------------------------*\
* Acumulates bytes in input buffer until 4 bytes are available. 
* Translate the 4 bytes from Base64 form and append to buffer.
* Returns new number of bytes in buffer.
\*-------------------------------------------------------------------------*/
static size_t b64decode(UC c, UC *input, size_t size, 
        luaL_Buffer *buffer)
{
    /* ignore invalid characters */
    if (b64unbase[c] > 64) return size;
    input[size++] = c;
    /* decode atom */
    if (size == 4) {
        UC decoded[3];
        int valid, value = 0;
        value =  b64unbase[input[0]]; value <<= 6;
        value |= b64unbase[input[1]]; value <<= 6;
        value |= b64unbase[input[2]]; value <<= 6;
        value |= b64unbase[input[3]];
        decoded[2] = (UC) (value & 0xff); value >>= 8;
        decoded[1] = (UC) (value & 0xff); value >>= 8;
        decoded[0] = (UC) value;
        /* take care of paddding */
        valid = (input[2] == '=') ? 1 : (input[3] == '=') ? 2 : 3; 
        luaL_addlstring(buffer, (char *) decoded, valid);
        return 0;
    /* need more data */
    } else return size;
}


/*-------------------------------------------------------------------------*\
* Incrementally applies the Base64 transfer content encoding to a string
* A, B = b64(C, D)
* A is the encoded version of the largest prefix of C .. D that is
* divisible by 3. B has the remaining bytes of C .. D, *without* encoding.
* The easiest thing would be to concatenate the two strings and 
* encode the result, but we can't afford that or Lua would dupplicate
* every chunk we received.
\*-------------------------------------------------------------------------*/
static int mime_global_b64(lua_State *L)
{
    UC atom[3];
    size_t isize = 0, asize = 0;
    const UC *input = (UC *) luaL_optlstring(L, 1, NULL, &isize);
    const UC *last = input + isize;
    luaL_Buffer buffer;
    /* end-of-input blackhole */
    if (!input) {
        lua_pushnil(L);
        lua_pushnil(L);
        return 2;
    }
    /* make sure we don't confuse buffer stuff with arguments */
    lua_settop(L, 2);
    /* process first part of the input */
    luaL_buffinit(L, &buffer);
    while (input < last) 
        asize = b64encode(*input++, atom, asize, &buffer);
    input = (UC *) luaL_optlstring(L, 2, NULL, &isize);
    /* if second part is nil, we are done */
    if (!input) {
        size_t osize = 0;
        asize = b64pad(atom, asize, &buffer);
        luaL_pushresult(&buffer);
        /* if the output is empty  and the input is nil, return nil */
        lua_tolstring(L, -1, &osize);
        if (osize == 0) lua_pushnil(L);
        lua_pushnil(L);
        return 2;
    }
    /* otherwise process the second part */
    last = input + isize;
    while (input < last) 
        asize = b64encode(*input++, atom, asize, &buffer);
    luaL_pushresult(&buffer);
    lua_pushlstring(L, (char *) atom, asize);
    return 2;
}

/*-------------------------------------------------------------------------*\
* Incrementally removes the Base64 transfer content encoding from a string
* A, B = b64(C, D)
* A is the encoded version of the largest prefix of C .. D that is
* divisible by 4. B has the remaining bytes of C .. D, *without* encoding.
\*-------------------------------------------------------------------------*/
static int mime_global_unb64(lua_State *L)
{
    UC atom[4];
    size_t isize = 0, asize = 0;
    const UC *input = (UC *) luaL_optlstring(L, 1, NULL, &isize);
    const UC *last = input + isize;
    luaL_Buffer buffer;
    /* end-of-input blackhole */
    if (!input) {
        lua_pushnil(L);
        lua_pushnil(L);
        return 2;
    }
    /* make sure we don't confuse buffer stuff with arguments */
    lua_settop(L, 2);
    /* process first part of the input */
    luaL_buffinit(L, &buffer);
    while (input < last) 
        asize = b64decode(*input++, atom, asize, &buffer);
    input = (UC *) luaL_optlstring(L, 2, NULL, &isize);
    /* if second is nil, we are done */
    if (!input) {
        size_t osize = 0;
        luaL_pushresult(&buffer);
        /* if the output is empty  and the input is nil, return nil */
        lua_tolstring(L, -1, &osize);
        if (osize == 0) lua_pushnil(L);
        lua_pushnil(L);
        return 2;
    }
    /* otherwise, process the rest of the input */
    last = input + isize;
    while (input < last) 
        asize = b64decode(*input++, atom, asize, &buffer);
    luaL_pushresult(&buffer);
    lua_pushlstring(L, (char *) atom, asize);
    return 2;
}

/*-------------------------------------------------------------------------*\
* Takes one byte and stuff it if needed. 
\*-------------------------------------------------------------------------*/
static size_t dot(int c, size_t state, luaL_Buffer *buffer)
{
    luaL_addchar(buffer, (char) c);
    switch (c) {
        case '\r': 
            return 1;
        case '\n': 
            return (state == 1)? 2: 0; 
        case '.':  
            if (state == 2) 
                luaL_addchar(buffer, '.');
        default:
            return 0;
    }
}

/*-------------------------------------------------------------------------*\
* Incrementally applies smtp stuffing to a string
* A, n = dot(l, D)
\*-------------------------------------------------------------------------*/
static int mime_global_dot(lua_State *L)
{
    size_t isize = 0, state = (size_t) luaL_checknumber(L, 1);
    const char *input = luaL_optlstring(L, 2, NULL, &isize);
    const char *last = input + isize;
    luaL_Buffer buffer;
    /* end-of-input blackhole */
    if (!input) {
        lua_pushnil(L);
        lua_pushnumber(L, 2);
        return 2;
    }
    /* process all input */
    luaL_buffinit(L, &buffer);
    while (input < last) 
        state = dot(*input++, state, &buffer);
    luaL_pushresult(&buffer);
    lua_pushnumber(L, (lua_Number) state);
    return 2;
}

/* ------------------------------------------------------------------ */
static inline int
read_size(uint8_t * buffer) {
	//bsize==2
	int r = (int)buffer[0] << 8 | (int)buffer[1];
	return r;
}

static inline void
write_size(uint8_t * buffer, int len) {
	//bsize==2
	buffer[0] = (len >> 8) & 0xff;
	buffer[1] = len & 0xff;
}

void printbytes(char *buffer,int sz){
	int i=0;
	printf("printbytes : ");
	for (i=0;i<sz;i++) {
		printf("%d ",(int)(buffer[i]));
	}
	printf("\n");
}

static int
lpack2stream(lua_State *L) {
	int bsize = (int) luaL_checkinteger(L, 1);
	int index = 2;
	void *buffer;
	size_t sz = 0;
	uint8_t * newbuffer;
	if (lua_isuserdata(L,index)) {
		buffer = lua_touserdata(L,index);
		sz = luaL_checkinteger(L,index+1);
		if (sz > 0x10000) {
			return luaL_error(L, "Invalid size (too long) of data : %d", (int)sz);
		}
		newbuffer = skynet_malloc(sz+bsize);
        memset(newbuffer, 0, bsize);
		memcpy(newbuffer+bsize, buffer, sz);
	} else {
		const char * str =  (const char *)luaL_checklstring(L, index, &sz);
		if (sz > 0x10000) {
			return luaL_error(L, "Invalid size (too long) of data : %d", (int)sz);
		}
		newbuffer = skynet_malloc(sz+bsize);
        memset(newbuffer, 0, bsize);
		memcpy(newbuffer+bsize, str, sz);
	}
	write_size(newbuffer, sz);
	lua_pushlightuserdata(L, (char *)newbuffer);
	lua_pushinteger(L, sz+bsize);
	printbytes((char*)newbuffer,sz+bsize);
	return 2;
}

static int
lunpack2streamh(lua_State *L) {
//	int bsize = (int) luaL_checkinteger(L, 1);
	printf("lunpack2streamh\n");
	void * buffer;
	int index=2;
	size_t sz;
	if (lua_isuserdata(L,index)) {
		buffer = lua_touserdata(L,index);
		sz = luaL_checkinteger(L,index+1);
	}else{
		const char * str =  (const char *)luaL_checklstring(L, index, &sz);
		buffer = skynet_malloc(sz);
		memcpy(buffer, str, sz);
	}
	printbytes(buffer,sz);
	printf("before read %zd \n",sz);
	int bsz = read_size((uint8_t *)buffer);
	lua_pushinteger(L,bsz);
	printf("lunpack2streamh end %d\n",bsz);
	return 1;
}

static int
lunpack2streamb(lua_State *L) {
	printf("lunpack2streamb\n");
	int bsize = (int) luaL_checkinteger(L, 1);
	void *buffer;
	int bsz,index = 2;
	size_t sz = 2;
	if (lua_isuserdata(L,index)) {
		buffer = lua_touserdata(L,index);
		bsz = luaL_checkinteger(L,index+1);
	} else {
		const char * str =  luaL_checklstring(L, index, &sz);
		buffer = skynet_malloc(sz);
		memcpy(buffer, str, sz);
		bsz = luaL_checkinteger(L,index+1);
	}
	printbytes(buffer+bsize,bsz);
	printf("debug[[1] %zd %d \n",sz,bsz);
	uint8_t * newbuffer = skynet_malloc(bsz);
	memcpy(newbuffer, buffer+bsize, bsz);
	lua_pushlightuserdata(L, (void *)newbuffer);
	lua_pushlightuserdata(L, (void *)(buffer+bsize+bsz));
	return 2;
}

static int
lcombinestream(lua_State *L) {
    void *buffer1 = lua_touserdata(L,1);
    int sz1 = luaL_checkinteger(L,2);
    void *buffer2 = lua_touserdata(L,3);
    int sz2 = luaL_checkinteger(L,4);
    int sz = sz1+sz2;
    uint8_t * newbuffer = skynet_malloc(sz);
    memset(newbuffer, 0, sz);
    memcpy(newbuffer, buffer1, sz1);
    memcpy(newbuffer+sz1, buffer2, sz2);
    lua_pushlightuserdata(L, (void *)newbuffer);
    lua_pushinteger(L, sz);
    skynet_free(buffer1);
    skynet_free(buffer2);
    return 2;
}

static int
lexitprocess(lua_State *L) {
    exit(0);
}

static int 
lskynetfree(lua_State *L) {
   void *buffer1 = lua_touserdata(L,1);
   skynet_free(buffer1);
   return 0;
}

/* ------------------------------------------------------------------ */

int
luaopen_gatepack(lua_State *L) {
	luaL_checkversion(L);
	luaL_Reg l[] = {
		{ "pack", lpack },
		
		{ "pack2stream", lpack2stream },
		{ "unpack2streamh", lunpack2streamh },
		{ "unpack2streamb", lunpack2streamb },
        { "combinestream", lcombinestream },

        { "skynetfree", lskynetfree },
        { "exitprocess", lexitprocess },
		
		{ "b64", mime_global_b64 },
		{ "unb64", mime_global_unb64 },
		{ "dot", mime_global_dot },
		
		{ NULL, NULL },
	};
	luaL_newlib(L,l);

	// the order is same with macros : TYPE_* (defined top)
	lua_pushliteral(L, "data");
	lua_pushliteral(L, "more");
	lua_pushliteral(L, "error");
	lua_pushliteral(L, "open");
	lua_pushliteral(L, "close");

	lua_pushcclosure(L, lfilter, 5);
	lua_setfield(L, -2, "filter");

	return 1;
}
