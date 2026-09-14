'use client';

import React, { useState } from 'react';
import { Camera } from '../../types/camera';
import { VideoSourceFactory } from '../../core/video-sources/video-source.factory';
import { StreamingGateway, GatewaySession } from '../../core/video-sources/streaming-gateway';
import { Video, Server, Play, ShieldCheck, Activity, Edit3, Trash2 } from 'lucide-react';

interface CameraListProps {
  cameras: Camera[];
  onEdit: (camera: Camera) => void;
  onDelete: (id: string) => void;
}

export function CameraList({ cameras, onEdit, onDelete }: CameraListProps) {
  const [activeSession, setActiveSession] = useState<GatewaySession | null>(null);
  const [gatewayStatusMessage, setGatewayStatusMessage] = useState<string | null>(null);

  const handleTestStream = async (camera: Camera) => {
    try {
      setGatewayStatusMessage(`Initializing Streaming Gateway for '${camera.name}'...`);
      const gateway = new StreamingGateway();
      const videoSource = VideoSourceFactory.create(camera);
      const session = await gateway.initializeStreamPipeline(videoSource);
      setActiveSession(session);
      setGatewayStatusMessage(
        `Stream Active! Transport: ${session.pipeline.connectionConfig.transportType} | Endpoint: ${session.descriptor.streamEndpoint}`
      );
    } catch (err: unknown) {
      setGatewayStatusMessage(
        `Failed to start stream: ${err instanceof Error ? err.message : String(err)}`
      );
    }
  };

  return (
    <div className="space-y-4">
      {gatewayStatusMessage && (
        <div className="rounded-xl border border-cyan-800/80 bg-cyan-950/40 p-4 text-xs text-cyan-200 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <Activity className="h-4 w-4 animate-pulse text-cyan-400" />
            <span>{gatewayStatusMessage}</span>
          </div>
          {activeSession && (
            <button
              onClick={() => {
                setActiveSession(null);
                setGatewayStatusMessage(null);
              }}
              className="text-xs text-cyan-400 hover:underline"
            >
              Close
            </button>
          )}
        </div>
      )}

      <div className="overflow-hidden rounded-xl border border-slate-800 bg-slate-900 shadow-xl">
        <table className="w-full text-left text-sm text-slate-300">
          <thead className="border-b border-slate-800 bg-slate-950/80 text-xs uppercase tracking-wider text-slate-400">
            <tr>
              <th className="px-6 py-3.5">Camera Name</th>
              <th className="px-6 py-3.5">Source Architecture</th>
              <th className="px-6 py-3.5">Details</th>
              <th className="px-6 py-3.5">Status</th>
              <th className="px-6 py-3.5">Security</th>
              <th className="px-6 py-3.5 text-right">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-800/60">
            {cameras.map((camera) => (
              <tr key={camera.id} className="hover:bg-slate-800/30 transition">
                <td className="px-6 py-4">
                  <div className="font-semibold text-slate-100">{camera.name}</div>
                  <div className="text-xs text-slate-500">{camera.location_description || 'No location set'}</div>
                </td>
                <td className="px-6 py-4">
                  {camera.source_type === 'rtsp' ? (
                    <span className="inline-flex items-center gap-1.5 rounded-full bg-cyan-950/80 border border-cyan-700/50 px-3 py-1 text-xs font-medium text-cyan-300">
                      <Server className="h-3 w-3" />
                      RTSP
                    </span>
                  ) : (
                    <span className="inline-flex items-center gap-1.5 rounded-full bg-purple-950/80 border border-purple-700/50 px-3 py-1 text-xs font-medium text-purple-300">
                      <Video className="h-3 w-3" />
                      Hikvision P2P
                    </span>
                  )}
                </td>
                <td className="px-6 py-4 text-xs font-mono text-slate-400">
                  {camera.source_type === 'rtsp' ? (
                    <span className="truncate block max-w-xs">{camera.rtsp_url}</span>
                  ) : (
                    <div>
                      <div>Dev: {camera.hik_device_id}</div>
                      <div>Ch: {camera.hik_channel} | SN: {camera.hik_serial_number || 'N/A'}</div>
                    </div>
                  )}
                </td>
                <td className="px-6 py-4">
                  <span className="inline-flex items-center gap-1.5 text-xs text-emerald-400">
                    <span className="h-2 w-2 rounded-full bg-emerald-500 animate-ping" />
                    Online ({camera.stream_profile})
                  </span>
                </td>
                <td className="px-6 py-4">
                  <span className="inline-flex items-center gap-1 text-xs text-slate-400">
                    <ShieldCheck className="h-3.5 w-3.5 text-emerald-400" />
                    Vault Protected
                  </span>
                </td>
                <td className="px-6 py-4 text-right">
                  <div className="flex items-center justify-end gap-2">
                    <button
                      onClick={() => handleTestStream(camera)}
                      title="Test via Streaming Gateway"
                      className="rounded-lg p-1.5 text-cyan-400 hover:bg-cyan-950/50 hover:text-cyan-200 transition"
                    >
                      <Play className="h-4 w-4" />
                    </button>
                    <button
                      onClick={() => onEdit(camera)}
                      title="Edit Camera"
                      className="rounded-lg p-1.5 text-slate-400 hover:bg-slate-800 hover:text-slate-100 transition"
                    >
                      <Edit3 className="h-4 w-4" />
                    </button>
                    <button
                      onClick={() => onDelete(camera.id)}
                      title="Delete Camera"
                      className="rounded-lg p-1.5 text-red-400 hover:bg-red-950/50 hover:text-red-200 transition"
                    >
                      <Trash2 className="h-4 w-4" />
                    </button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
