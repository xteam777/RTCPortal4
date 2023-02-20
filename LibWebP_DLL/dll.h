#ifndef _DLL_H_
#define _DLL_H_

#if BUILDING_DLL
#define DLLIMPORT __declspec(dllexport)
#else
#define DLLIMPORT __declspec(dllimport)
#endif

#define WEBP_EXTERN __declspec(dllexport)
#include "Original\Include\WebP\types.h"
#include "Original\Include\WebP\encode.h"
#include "Original\Include\WebP\decode.h"
#include "Original\Include\WebP\demux.h"
#include "Original\Include\WebP\mux.h"
#include "Original\Include\WebP\mux_types.h"
//DLLIMPORT
// size_t WebPEncodeLosslessRGB(const uint8_t* rgb,
  //                                       int width, int height, int stride,
    //                                     uint8_t** output);

//DLLIMPORT 
//uint8_t* WebPDecodeRGBInto1(
 //   const uint8_t* data, size_t data_size,
 //   uint8_t* output_buffer, size_t output_buffer_size, int output_stride);

/*WEBP_EXTERN size_t WebPEncodeLosslessRGB(const uint8_t* rgb,
                                         int width, int height, int stride,
                                         uint8_t** output);

WEBP_EXTERN uint8_t* WebPDecodeRGBInto(
    const uint8_t* data, size_t data_size,
    uint8_t* output_buffer, size_t output_buffer_size, int output_stride);
*/

//DLLIMPORT void HelloWorld();

#endif
