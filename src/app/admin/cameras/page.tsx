'use client';

import React, { useState } from 'react';
import { Camera } from '../../../types/camera';
import { SEED_CAMERAS, SEED_COMPANIES, SEED_BRANDS, SEED_BRANCHES } from '../../../data/mock-db';
import { CameraList } from '../../../components/admin/CameraList';
import { CameraFormModal } from '../../../components/admin/CameraFormModal';
import { Video, Server, Plus, ShieldCheck, Building2, Store } from 'lucide-react';

export default function AdminCamerasPage() {
  const [cameras, setCameras] = useState<Camera[]>(SEED_CAMERAS.slice(0, 2)); // Ego cameras
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingCamera, setEditingCamera] = useState<Camera | null>(null);

  const selectedCompany = SEED_COMPANIES[0]; // Ego
  const selectedBrand = SEED_BRANDS[0];
  const selectedBranch = SEED_BRANCHES[0]; // Ego Mall of Arabia

  const handleSaveCamera = (cameraData: Partial<Camera>) => {
    if (editingCamera) {
      setCameras((prev) =>
        prev.map((c) => (c.id === editingCamera.id ? ({ ...c, ...cameraData } as Camera) : c))
      );
    } else {
      setCameras((prev) => [...prev, cameraData as Camera]);
    }
    setEditingCamera(null);
  };

  const handleEdit = (camera: Camera) => {
    setEditingCamera(camera);
    setIsModalOpen(true);
  };

  const handleDelete = (id: string) => {
    setCameras((prev) => prev.filter((c) => c.id !== id));
  };

  const rtspCount = cameras.filter((c) => c.source_type === 'rtsp').length;
  const hikCount = cameras.filter((c) => c.source_type === 'hikvision_p2p').length;

  return (
    <div className="min-h-screen bg-slate-950 p-8 text-slate-100">
      <div className="mx-auto max-w-7xl space-y-8">
        {/* Header */}
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 border-b border-slate-800 pb-6">
          <div>
            <div className="flex items-center gap-3">
              <div className="rounded-xl bg-cyan-500/10 p-2.5 text-cyan-400 border border-cyan-500/20">
                <Video className="h-6 w-6" />
              </div>
              <div>
                <h1 className="text-2xl font-bold tracking-tight text-slate-100">
                  LensIQ Camera Administration
                </h1>
                <p className="text-sm text-slate-400">
                  Phase 1 — Multi-Source Camera Architecture (RTSP & Hikvision P2P)
                </p>
              </div>
            </div>
          </div>

          {/* Tenant Selector Badges */}
          <div className="flex items-center gap-3">
            <div className="flex items-center gap-2 rounded-lg border border-slate-800 bg-slate-900 px-3 py-1.5 text-xs text-slate-300">
              <Building2 className="h-3.5 w-3.5 text-cyan-400" />
              <span>Company: <strong className="text-slate-100">{selectedCompany.name}</strong></span>
            </div>
            <div className="flex items-center gap-2 rounded-lg border border-slate-800 bg-slate-900 px-3 py-1.5 text-xs text-slate-300">
              <Store className="h-3.5 w-3.5 text-purple-400" />
              <span>Branch: <strong className="text-slate-100">{selectedBranch.name}</strong></span>
            </div>
            <button
              onClick={() => {
                setEditingCamera(null);
                setIsModalOpen(true);
              }}
              className="flex items-center gap-2 rounded-lg bg-cyan-600 px-4 py-2 text-sm font-semibold text-white shadow-lg shadow-cyan-950/50 hover:bg-cyan-500 transition"
            >
              <Plus className="h-4 w-4" />
              Add Camera
            </button>
          </div>
        </div>

        {/* Stats Cards */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          <div className="rounded-xl border border-slate-800 bg-slate-900 p-5 shadow-lg">
            <div className="text-xs font-semibold uppercase tracking-wider text-slate-400">
              Total Managed Cameras
            </div>
            <div className="mt-2 text-3xl font-bold text-slate-100">{cameras.length}</div>
            <div className="mt-1 text-xs text-slate-500">Across Ego Mall of Arabia Branch</div>
          </div>

          <div className="rounded-xl border border-cyan-950/80 bg-cyan-950/20 p-5 shadow-lg">
            <div className="flex items-center justify-between">
              <div className="text-xs font-semibold uppercase tracking-wider text-cyan-400">
                RTSP Direct Streams
              </div>
              <Server className="h-4 w-4 text-cyan-400" />
            </div>
            <div className="mt-2 text-3xl font-bold text-cyan-200">{rtspCount}</div>
            <div className="mt-1 text-xs text-cyan-400/70">e.g. Cashier 01</div>
          </div>

          <div className="rounded-xl border border-purple-950/80 bg-purple-950/20 p-5 shadow-lg">
            <div className="flex items-center justify-between">
              <div className="text-xs font-semibold uppercase tracking-wider text-purple-400">
                Hikvision P2P Feeds
              </div>
              <Video className="h-4 w-4 text-purple-400" />
            </div>
            <div className="mt-2 text-3xl font-bold text-purple-200">{hikCount}</div>
            <div className="mt-1 text-xs text-purple-400/70">e.g. Main Entrance</div>
          </div>

          <div className="rounded-xl border border-emerald-950/80 bg-emerald-950/20 p-5 shadow-lg">
            <div className="flex items-center justify-between">
              <div className="text-xs font-semibold uppercase tracking-wider text-emerald-400">
                Zero Credential Leakage
              </div>
              <ShieldCheck className="h-4 w-4 text-emerald-400" />
            </div>
            <div className="mt-2 text-3xl font-bold text-emerald-300">100%</div>
            <div className="mt-1 text-xs text-emerald-400/70">Vault Protected Architecture</div>
          </div>
        </div>

        {/* Camera List */}
        <div className="space-y-4">
          <div className="flex items-center justify-between">
            <h2 className="text-lg font-semibold text-slate-100">Configured Cameras</h2>
            <div className="text-xs text-slate-400">
              Click the play button to test the Streaming Gateway abstraction pipeline.
            </div>
          </div>
          <CameraList cameras={cameras} onEdit={handleEdit} onDelete={handleDelete} />
        </div>

        {/* Modal */}
        <CameraFormModal
          isOpen={isModalOpen}
          onClose={() => {
            setIsModalOpen(false);
            setEditingCamera(null);
          }}
          onSave={handleSaveCamera}
          initialCamera={editingCamera}
          companyId={selectedCompany.id}
          brandId={selectedBrand.id}
          branchId={selectedBranch.id}
        />
      </div>
    </div>
  );
}
