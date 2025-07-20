// LDAC A2DP Windows Driver Header
// Simplified for registry-based codec management
// Copyright (c) 2024 LDAC Driver Team

#pragma once

// LDAC codec definitions
#define LDAC_CODEC_ID           0x2D
#define LDAC_MAX_BITRATE        990000
#define LDAC_MID_BITRATE        660000
#define LDAC_MIN_BITRATE        330000

// Registry keys for codec management
#define LDAC_REGISTRY_KEY       L"SOFTWARE\\LDACDriver"
#define LDAC_ENABLED_VALUE      L"LDACEnabled"
#define LDAC_BITRATE_VALUE      L"PreferredBitrate"
#define LDAC_ADAPTIVE_VALUE     L"AdaptiveBitrate"

// LDAC codec configuration
typedef struct _LDAC_CODEC_CONFIG {
    unsigned int Bitrate;
    unsigned int SamplingFreq;
    unsigned char ChannelMode;
    unsigned char BitDepth;
} LDAC_CODEC_CONFIG;

// Function declarations for codec management
int LDACInitializeCodec(void);
int LDACSetBitrate(unsigned int Bitrate);
int LDACGetCapabilities(unsigned int* Capabilities);
int LDACIsEnabled(int* Enabled);
int LDACConfigureRegistry(void);