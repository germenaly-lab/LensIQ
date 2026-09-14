'use client';

import React, { useState } from 'react';
import { Camera, CameraSourceType, StreamProfile } from '../../types/camera';
import { X, ShieldAlert, Video, Server, KeyRound, Check } from 'lucide-react';

interface CameraFormModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSave: (camera: Partial<Camera>) => void;
  initialCamera?: Camera | null;
  companyId: string;
  brandId: string;
  branchId: string;
}

export function CameraFormModal({
  isOpen,
  onClose,
  onSave,
  initialCamera,
  companyId,
  brandId,
  branchId,
}: CameraFormModalProps) {
  const [sourceType, setSourceType] = useState<CameraSourceType>(
    initialCamera?.source_type || 'rtsp'
  );
  const [name, setName] = useState(initialCamera?.name || '');
  const [locationDesc, setLocationDesc] = useState(initialCamera?.location_description || '');
  const [streamProfile, setStreamProfile] = useState<StreamProfile>(
    initialCamera?.stream_profile || 'main'
  );

  // RTSP fields
  const [rtspUrl, setRtspUrl] = useState(initialCamera?.rtsp_url || '');
  const [rtspUsernameRef, setRtspUsernameRef] = useState('vault-rtsp-user-ref');
  const [rtspPasswordRef, setRtspPasswordRef] = useState('vault-rtsp-pass-ref');

  // Hikvision P2P fields
  const [hikDeviceId, setHikDeviceId] = useState(initialCamera?.hik_device_id || '');
  const [hikSerialNumber, setHikSerialNumber] = useState(initialCamera?.hik_serial_number || '');
  const [hikChannel, setHikChannel] = useState(initialCamera?.hik_channel || 1);
  const [hikCredentialRef, setHikCredentialRef] = useState(
    initialCamera?.credentials_reference || 'vault-hik-appkey-ref'
  );

  const [formError, setFormError] = useState<string | null>(null);

  if (!isOpen) return null;

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setFormError(null);

    if (!name.trim()) {
      setFormError('Camera name is required.');
      return;
    }

    if (sourceType === 'rtsp') {
      if (!rtspUrl.trim() || (!rtspUrl.startsWith('rtsp://') && !rtspUrl.startsWith('rtsps://'))) {
        setFormError('A valid RTSP URL starting with rtsp:// or rtsps:// is required.');
        return;
      }

      onSave({
        id: initialCamera?.id || `cam_${Date.now()}`,
        company_id: companyId,
        brand_id: brandId,
        branch_id: branchId,
        name,
        source_type: 'rtsp',
        enabled: true,
        status: initialCamera?.status || 'online',
        location_description: locationDesc,
        rtsp_url: rtspUrl,
        credentials_reference: `vault-rtsp-${Date.now()}`,
        stream_profile: streamProfile,
        last_seen_at: new Date().toISOString(),
        created_at: initialCamera?.created_at || new Date().toISOString(),
        updated_at: new Date().toISOString(),
      });
    } else {
      if (!hikDeviceId.trim()) {
        setFormError('Hikvision Device Identifier is required.');
        return;
      }
      if (hikChannel < 1) {
        setFormError('Hikvision Channel must be 1 or higher.');
        return;
      }

      onSave({
        id: initialCamera?.id || `cam_${Date.now()}`,
        company_id: companyId,
        brand_id: brandId,
        branch_id: branchId,
        name,
        source_type: 'hikvision_p2p',
        enabled: true,
        status: initialCamera?.status || 'online',
        location_description: locationDesc,
        hik_device_id: hikDeviceId,
        hik_serial_number: hikSerialNumber || null,
        hik_channel: Number(hikChannel),
        credentials_reference: hikCredentialRef,
        stream_profile: streamProfile,
        last_seen_at: new Date().toISOString(),
        created_at: initialCamera?.created_at || new Date().toISOString(),
        updated_at: new Date().toISOString(),
      });
    }

    onClose();
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/80 backdrop-blur-sm p-4">
      <div className="w-full max-w-2xl rounded-xl border border-slate-800 bg-slate-900 shadow-2xl overflow-hidden">
        {/* Header */}
        <div className="flex items-center justify-between border-b border-slate-800 px-6 py-4">
          <div className="flex items-center gap-2">
            <Video className="h-5 w-5 text-cyan-400" />
            <h2 className="text-lg font-semibold text-slate-100">
              {initialCamera ? 'Edit Camera Configuration' : 'Add Multi-Source Camera'}
            </h2>
          </div>
          <button
            onClick={onClose}
            className="rounded-lg p-1 text-slate-400 hover:bg-slate-800 hover:text-slate-100"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        {/* Form */}
        <form onSubmit={handleSubmit} className="p-6 space-y-6">
          {formError && (
            <div className="rounded-lg bg-red-950/60 border border-red-800/80 p-3 text-sm text-red-200 flex items-center gap-2">
              <ShieldAlert className="h-4 w-4 shrink-0" />
              <span>{formError}</span>
            </div>
          )}

          {/* Common Details */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-medium uppercase tracking-wider text-slate-400 mb-1">
                Camera Name
              </label>
              <input
                type="text"
                value={name}
                onChange={(e) => setName(e.target.value)}
                placeholder="e.g. Cashier 01, Main Entrance"
                className="w-full rounded-lg border border-slate-700 bg-slate-950 px-3 py-2 text-sm text-slate-100 placeholder-slate-500 focus:border-cyan-500 focus:outline-none"
                required
              />
            </div>
            <div>
              <label className="block text-xs font-medium uppercase tracking-wider text-slate-400 mb-1">
                Location Description
              </label>
              <input
                type="text"
                value={locationDesc}
                onChange={(e) => setLocationDesc(e.target.value)}
                placeholder="e.g. Ground Floor, Checkout area"
                className="w-full rounded-lg border border-slate-700 bg-slate-950 px-3 py-2 text-sm text-slate-100 placeholder-slate-500 focus:border-cyan-500 focus:outline-none"
              />
            </div>
          </div>

          {/* Source Type Selector */}
          <div>
            <label className="block text-xs font-medium uppercase tracking-wider text-slate-400 mb-2">
              Video Source Architecture
            </label>
            <div className="grid grid-cols-2 gap-3">
              <button
                type="button"
                onClick={() => setSourceType('rtsp')}
                className={`flex items-center justify-between rounded-lg border p-3 text-left transition ${
                  sourceType === 'rtsp'
                    ? 'border-cyan-500 bg-cyan-950/30 text-cyan-200 ring-1 ring-cyan-500'
                    : 'border-slate-800 bg-slate-950/50 text-slate-400 hover:border-slate-700'
                }`}
              >
                <div className="flex items-center gap-2.5">
                  <Server className="h-4 w-4 text-cyan-400" />
                  <div>
                    <div className="text-sm font-semibold text-slate-200">RTSP Stream</div>
                    <div className="text-xs text-slate-400">Direct TCP/UDP endpoint</div>
                  </div>
                </div>
                {sourceType === 'rtsp' && <Check className="h-4 w-4 text-cyan-400" />}
              </button>

              <button
                type="button"
                onClick={() => setSourceType('hikvision_p2p')}
                className={`flex items-center justify-between rounded-lg border p-3 text-left transition ${
                  sourceType === 'hikvision_p2p'
                    ? 'border-purple-500 bg-purple-950/30 text-purple-200 ring-1 ring-purple-500'
                    : 'border-slate-800 bg-slate-950/50 text-slate-400 hover:border-slate-700'
                }`}
              >
                <div className="flex items-center gap-2.5">
                  <Video className="h-4 w-4 text-purple-400" />
                  <div>
                    <div className="text-sm font-semibold text-slate-200">Hikvision P2P</div>
                    <div className="text-xs text-slate-400">Hik-Connect Cloud Gateway</div>
                  </div>
                </div>
                {sourceType === 'hikvision_p2p' && <Check className="h-4 w-4 text-purple-400" />}
              </button>
            </div>
          </div>

          {/* DYNAMIC FIELDS: RTSP */}
          {sourceType === 'rtsp' && (
            <div className="rounded-lg border border-cyan-900/40 bg-cyan-950/10 p-4 space-y-4">
              <h3 className="text-xs font-semibold uppercase tracking-wider text-cyan-400">
                RTSP Source Configuration
              </h3>
              <div>
                <label className="block text-xs font-medium text-slate-300 mb-1">RTSP URL</label>
                <input
                  type="text"
                  value={rtspUrl}
                  onChange={(e) => setRtspUrl(e.target.value)}
                  placeholder="rtsp://stream.domain.com:554/live/stream1"
                  className="w-full rounded-lg border border-slate-700 bg-slate-950 px-3 py-2 text-sm text-slate-100 placeholder-slate-600 focus:border-cyan-500 focus:outline-none"
                />
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-medium text-slate-300 mb-1">
                    Username Credential Reference
                  </label>
                  <input
                    type="text"
                    value={rtspUsernameRef}
                    onChange={(e) => setRtspUsernameRef(e.target.value)}
                    className="w-full rounded-lg border border-slate-700 bg-slate-950 px-3 py-2 text-sm text-slate-300 focus:border-cyan-500 focus:outline-none"
                  />
                </div>
                <div>
                  <label className="block text-xs font-medium text-slate-300 mb-1">
                    Password Credential Reference
                  </label>
                  <input
                    type="text"
                    value={rtspPasswordRef}
                    onChange={(e) => setRtspPasswordRef(e.target.value)}
                    className="w-full rounded-lg border border-slate-700 bg-slate-950 px-3 py-2 text-sm text-slate-300 focus:border-cyan-500 focus:outline-none"
                  />
                </div>
              </div>
            </div>
          )}

          {/* DYNAMIC FIELDS: Hikvision P2P */}
          {sourceType === 'hikvision_p2p' && (
            <div className="rounded-lg border border-purple-900/40 bg-purple-950/10 p-4 space-y-4">
              <h3 className="text-xs font-semibold uppercase tracking-wider text-purple-400">
                Hikvision P2P Configuration
              </h3>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-medium text-slate-300 mb-1">
                    Hikvision Device Identifier
                  </label>
                  <input
                    type="text"
                    value={hikDeviceId}
                    onChange={(e) => setHikDeviceId(e.target.value)}
                    placeholder="e.g. HIK-DS-2CD2143G2-IS-01"
                    className="w-full rounded-lg border border-slate-700 bg-slate-950 px-3 py-2 text-sm text-slate-100 placeholder-slate-600 focus:border-purple-500 focus:outline-none"
                  />
                </div>
                <div>
                  <label className="block text-xs font-medium text-slate-300 mb-1">
                    Device Serial Number
                  </label>
                  <input
                    type="text"
                    value={hikSerialNumber}
                    onChange={(e) => setHikSerialNumber(e.target.value)}
                    placeholder="e.g. D12345678"
                    className="w-full rounded-lg border border-slate-700 bg-slate-950 px-3 py-2 text-sm text-slate-100 placeholder-slate-600 focus:border-purple-500 focus:outline-none"
                  />
                </div>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-medium text-slate-300 mb-1">
                    Channel Number
                  </label>
                  <input
                    type="number"
                    min={1}
                    max={128}
                    value={hikChannel}
                    onChange={(e) => setHikChannel(parseInt(e.target.value, 10) || 1)}
                    className="w-full rounded-lg border border-slate-700 bg-slate-950 px-3 py-2 text-sm text-slate-100 focus:border-purple-500 focus:outline-none"
                  />
                </div>
                <div>
                  <label className="block text-xs font-medium text-slate-300 mb-1">
                    Hik-Connect Credential Reference
                  </label>
                  <input
                    type="text"
                    value={hikCredentialRef}
                    onChange={(e) => setHikCredentialRef(e.target.value)}
                    className="w-full rounded-lg border border-slate-700 bg-slate-950 px-3 py-2 text-sm text-slate-300 focus:border-purple-500 focus:outline-none"
                  />
                </div>
              </div>
            </div>
          )}

          {/* Stream Profile & Security Note */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-medium uppercase tracking-wider text-slate-400 mb-1">
                Stream Profile
              </label>
              <select
                value={streamProfile}
                onChange={(e) => setStreamProfile(e.target.value as StreamProfile)}
                className="w-full rounded-lg border border-slate-700 bg-slate-950 px-3 py-2 text-sm text-slate-100 focus:border-cyan-500 focus:outline-none"
              >
                <option value="main">Main Profile (High Quality - 1080p/4K)</option>
                <option value="sub">Sub Profile (Low Bandwidth - 720p/360p)</option>
              </select>
            </div>

            <div className="flex items-center gap-2 rounded-lg border border-emerald-900/40 bg-emerald-950/20 p-3 text-xs text-emerald-300">
              <KeyRound className="h-4 w-4 shrink-0 text-emerald-400" />
              <span>
                <strong>Zero-Credential Leak:</strong> All credentials use vault references and are never sent to mobile or frontend clients.
              </span>
            </div>
          </div>

          {/* Actions */}
          <div className="flex justify-end gap-3 border-t border-slate-800 pt-4">
            <button
              type="button"
              onClick={onClose}
              className="rounded-lg border border-slate-700 px-4 py-2 text-sm font-medium text-slate-300 hover:bg-slate-800"
            >
              Cancel
            </button>
            <button
              type="submit"
              className="rounded-lg bg-cyan-600 px-5 py-2 text-sm font-semibold text-white hover:bg-cyan-500 shadow-md shadow-cyan-900/30"
            >
              Save Camera
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
