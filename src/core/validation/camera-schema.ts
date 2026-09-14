import { z } from 'zod';

export const streamProfileSchema = z.enum(['main', 'sub']);
export const cameraSourceTypeSchema = z.enum(['rtsp', 'hikvision_p2p']);
export const cameraStatusSchema = z.enum(['online', 'offline', 'degraded', 'provisioning']);

// Base fields common to all cameras
const baseCameraSchema = z.object({
  name: z.string().min(2, 'Camera name must be at least 2 characters').max(100),
  company_id: z.string().uuid('Valid company ID required'),
  brand_id: z.string().uuid('Valid brand ID required'),
  branch_id: z.string().uuid('Valid branch ID required'),
  enabled: z.boolean().default(true),
  status: cameraStatusSchema.default('offline'),
  location_description: z.string().max(255).optional().nullable(),
  stream_profile: streamProfileSchema.default('main'),
  credentials_reference: z.string().max(100).optional().nullable(),
});

// RTSP Camera Schema
export const rtspCameraSchema = baseCameraSchema.extend({
  source_type: z.literal('rtsp'),
  rtsp_url: z.string().url().refine(
    (url) => url.startsWith('rtsp://') || url.startsWith('rtsps://'),
    { message: 'RTSP URL must begin with rtsp:// or rtsps://' }
  ),
  hik_device_id: z.null().optional(),
  hik_serial_number: z.null().optional(),
  hik_channel: z.null().optional(),
  hik_username: z.null().optional(),
});

// Hikvision P2P Camera Schema
export const hikvisionP2PCameraSchema = baseCameraSchema.extend({
  source_type: z.literal('hikvision_p2p'),
  rtsp_url: z.null().optional(),
  hik_device_id: z.string().min(3, 'Hikvision Device ID is required'),
  hik_serial_number: z.string().min(3, 'Hikvision Serial Number is required').optional().nullable(),
  hik_channel: z.number().int().min(1, 'Channel must be 1 or higher').max(128),
  hik_username: z.string().max(50).optional().nullable(),
});

// Discriminated Union for strict runtime validation
export const createCameraSchema = z.discriminatedUnion('source_type', [
  rtspCameraSchema,
  hikvisionP2PCameraSchema,
]);

export type CreateCameraInput = z.infer<typeof createCameraSchema>;
export type RTSPCameraInput = z.infer<typeof rtspCameraSchema>;
export type HikvisionP2PCameraInput = z.infer<typeof hikvisionP2PCameraSchema>;
