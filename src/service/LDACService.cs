using System;
using System.Collections.Generic;
using System.ServiceProcess;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Win32;
using System.Diagnostics;

namespace LDACDriver.Service
{
    public class LDACService : ServiceBase
    {
        private Timer _monitorTimer;
        private readonly TimeSpan _monitorInterval = TimeSpan.FromSeconds(5);
        private readonly string _serviceName = "LDACA2DPService";
        private readonly string _displayName = "LDAC A2DP Audio Service";
        private readonly string _description = "Provides LDAC codec support for Bluetooth A2DP devices";

        public LDACService()
        {
            ServiceName = _serviceName;
            CanStop = true;
            CanShutdown = true;
            CanPauseAndContinue = false;
            AutoLog = true;
        }

        protected override void OnStart(string[] args)
        {
            EventLog.WriteEntry("LDAC Service starting...", EventLogEntryType.Information);
            
            _monitorTimer = new Timer(MonitorDevices, null, TimeSpan.Zero, _monitorInterval);
            
            EventLog.WriteEntry("LDAC Service started successfully", EventLogEntryType.Information);
        }

        protected override void OnStop()
        {
            EventLog.WriteEntry("LDAC Service stopping...", EventLogEntryType.Information);
            
            _monitorTimer?.Dispose();
            
            EventLog.WriteEntry("LDAC Service stopped", EventLogEntryType.Information);
        }

        protected override void OnShutdown()
        {
            OnStop();
        }

        private void MonitorDevices(object state)
        {
            try
            {
                EventLog.WriteEntry("Monitoring devices...", EventLogEntryType.Information);
            }
            catch (Exception ex)
            {
                EventLog.WriteEntry($"Error monitoring devices: {ex.Message}", EventLogEntryType.Error);
            }
        }

        public static void Main()
        {
            ServiceBase.Run(new LDACService());
        }
    }
}