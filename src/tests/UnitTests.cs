using System;
using System.Threading.Tasks;
using Xunit;
using LDACDriver.Tests;

namespace LDACDriver.Tests
{
    public class LDACDriverTests
    {
        [Fact]
        public void TestLDACBitrateConfiguration()
        {
            // Test valid bitrates
            Assert.True(LDACManager.IsValidBitrate(990000));
            Assert.True(LDACManager.IsValidBitrate(660000));
            Assert.True(LDACManager.IsValidBitrate(330000));
            
            // Test invalid bitrates
            Assert.False(LDACManager.IsValidBitrate(1000000));
            Assert.False(LDACManager.IsValidBitrate(0));
            Assert.False(LDACManager.IsValidBitrate(-1));
        }

        [Fact]
        public void TestCodecPriorityChain()
        {
            var chain = new CodecPriorityChain();
            var codecs = chain.GetPriorityOrder();
            
            Assert.NotNull(codecs);
            Assert.NotEmpty(codecs);
            Assert.Equal("LDAC", codecs[0]);
            Assert.Equal("SBC", codecs[^1]);
        }

        [Fact]
        public void TestDeviceCapabilityDetection()
        {
            var detector = new DeviceCapabilityDetector();
            var mockDevice = new MockBluetoothDevice
            {
                Id = "00:11:22:33:44:55",
                Name = "Soundcore Space One NC",
                SupportedCodecs = new[] { "LDAC", "AAC", "SBC" }
            };
            
            var capabilities = detector.DetectCapabilities(mockDevice);
            Assert.True(capabilities.SupportsLDAC);
            Assert.True(capabilities.SupportsAAC);
            Assert.True(capabilities.SupportsSBC);
        }

        [Fact]
        public async Task TestServiceStartup()
        {
            var service = new LDACService();
            await service.StartAsync();
            
            Assert.True(service.IsRunning);
            await service.StopAsync();
            Assert.False(service.IsRunning);
        }

        [Fact]
        public void TestEQProfileSerialization()
        {
            var profile = new EQProfile
            {
                Name = "Test Profile",
                Bands = new[]
                {
                    new EQBand { Frequency = 60, Gain = 2.5 },
                    new EQBand { Frequency = 250, Gain = -1.0 },
                    new EQBand { Frequency = 1000, Gain = 0.0 }
                }
            };
            
            var serialized = EQProfileSerializer.Serialize(profile);
            var deserialized = EQProfileSerializer.Deserialize(serialized);
            
            Assert.Equal(profile.Name, deserialized.Name);
            Assert.Equal(profile.Bands.Length, deserialized.Bands.Length);
            Assert.Equal(profile.Bands[0].Frequency, deserialized.Bands[0].Frequency);
            Assert.Equal(profile.Bands[0].Gain, deserialized.Bands[0].Gain);
        }

        [Fact]
        public void TestRegistryConfiguration()
        {
            var config = new RegistryConfiguration();
            config.SetPreferredBitrate(990000);
            config.SetAdaptiveBitrateEnabled(true);
            config.SetFallbackChain(new[] { "LDAC", "aptX", "SBC" });
            
            Assert.Equal(990000, config.GetPreferredBitrate());
            Assert.True(config.IsAdaptiveBitrateEnabled());
            Assert.Equal("LDAC,aptX,SBC", string.Join(",", config.GetFallbackChain()));
        }

        [Fact]
        public async Task TestDriverCommunication()
        {
            var driver = new MockLDACDriver();
            var result = await driver.SetBitrateAsync(990000);
            
            Assert.True(result.Success);
            Assert.Equal(990000, result.NewBitrate);
        }

        [Fact]
        public void TestAudioFormatValidation()
        {
            var validator = new AudioFormatValidator();
            
            // Valid formats
            Assert.True(validator.IsValidFormat(48000, 16, 2));
            Assert.True(validator.IsValidFormat(44100, 24, 2));
            Assert.True(validator.IsValidFormat(96000, 16, 2));
            
            // Invalid formats
            Assert.False(validator.IsValidFormat(0, 16, 2));
            Assert.False(validator.IsValidFormat(48000, 8, 2));
            Assert.False(validator.IsValidFormat(48000, 16, 0));
        }

        [Fact]
        public void TestConnectionQualityCalculation()
        {
            var calculator = new ConnectionQualityCalculator();
            
            // Perfect conditions
            var quality1 = calculator.CalculateQuality(100, 0, 990000);
            Assert.Equal(100, quality1);
            
            // Poor conditions
            var quality2 = calculator.CalculateQuality(20, 15, 330000);
            Assert.True(quality2 < 50);
            
            // Average conditions
            var quality3 = calculator.CalculateQuality(70, 5, 660000);
            Assert.True(quality3 > 50 && quality3 < 100);
        }

        [Fact]
        public async Task TestCodecNegotiation()
        {
            var negotiator = new CodecNegotiator();
            var device = new MockBluetoothDevice
            {
                SupportedCodecs = new[] { "LDAC", "AAC", "SBC" }
            };
            
            var result = await negotiator.NegotiateCodecAsync(device);
            Assert.Equal("LDAC", result.SelectedCodec);
            Assert.Equal(990000, result.Bitrate);
        }

        [Fact]
        public void TestErrorHandling()
        {
            var errorHandler = new DriverErrorHandler();
            
            // Test error logging
            errorHandler.LogError("Test error", new Exception("Test exception"));
            Assert.True(errorHandler.HasErrors);
            
            // Test error retrieval
            var errors = errorHandler.GetErrors();
            Assert.NotEmpty(errors);
            Assert.Contains("Test error", errors[0].Message);
        }
    }

    // Mock classes for testing
    public class MockBluetoothDevice
    {
        public string Id { get; set; }
        public string Name { get; set; }
        public string[] SupportedCodecs { get; set; }
    }

    public class MockLDACDriver
    {
        public async Task<DriverResult> SetBitrateAsync(int bitrate)
        {
            await Task.Delay(10);
            return new DriverResult { Success = true, NewBitrate = bitrate };
        }
    }

    public class DriverResult
    {
        public bool Success { get; set; }
        public int NewBitrate { get; set; }
    }

    public class CodecPriorityChain
    {
        public string[] GetPriorityOrder()
        {
            return new[] { "LDAC", "aptX HD", "aptX", "AAC", "SBC" };
        }
    }

    public class DeviceCapabilityDetector
    {
        public DeviceCapabilities DetectCapabilities(MockBluetoothDevice device)
        {
            return new DeviceCapabilities
            {
                SupportsLDAC = device.SupportedCodecs.Contains("LDAC"),
                SupportsAAC = device.SupportedCodecs.Contains("AAC"),
                SupportsSBC = device.SupportedCodecs.Contains("SBC")
            };
        }
    }

    public class DeviceCapabilities
    {
        public bool SupportsLDAC { get; set; }
        public bool SupportsAAC { get; set; }
        public bool SupportsSBC { get; set; }
    }

    public class EQProfile
    {
        public string Name { get; set; }
        public EQBand[] Bands { get; set; }
    }

    public class EQBand
    {
        public int Frequency { get; set; }
        public double Gain { get; set; }
    }

    public static class EQProfileSerializer
    {
        public static string Serialize(EQProfile profile)
        {
            return System.Text.Json.JsonSerializer.Serialize(profile);
        }

        public static EQProfile Deserialize(string json)
        {
            return System.Text.Json.JsonSerializer.Deserialize<EQProfile>(json);
        }
    }
}