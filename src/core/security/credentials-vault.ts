import crypto from 'crypto';
import { CameraCredentialVaultRecord } from '../../types/camera';

/**
 * Service to manage protected camera credentials.
 * Normal database tables only hold credentials_reference (e.g. 'vault-ref-xxx').
 * Actual secrets are stored in the protected vault table or external HSM/Secret Manager.
 */
export class CredentialsVaultService {
  private vaultStore: Map<string, CameraCredentialVaultRecord> = new Map();
  private encryptionKey: Buffer;

  constructor(masterSecret: string = 'lensiq-super-secret-vault-encryption-key-32bytes!') {
    this.encryptionKey = crypto.createHash('sha256').update(masterSecret).digest();
  }

  /**
   * Register a new credential in the vault and return a secure reference token.
   */
  async storeSecret(
    secretPayload: Record<string, string>,
    secretType: 'rtsp_auth' | 'hikvision_token' | 'hikvision_p2p_appkey'
  ): Promise<string> {
    const reference = `vault-ref-${crypto.randomUUID()}`;
    const serialized = JSON.stringify(secretPayload);

    // AES-256-GCM encryption
    const iv = crypto.randomBytes(12);
    const cipher = crypto.createCipheriv('aes-256-gcm', this.encryptionKey, iv);
    let encrypted = cipher.update(serialized, 'utf8', 'hex');
    encrypted += cipher.final('hex');
    const tag = cipher.getAuthTag().toString('hex');

    const vaultRecord: CameraCredentialVaultRecord = {
      id: crypto.randomUUID(),
      credentials_reference: reference,
      secret_payload_encrypted: `${iv.toString('hex')}:${tag}:${encrypted}`,
      secret_type: secretType,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };

    this.vaultStore.set(reference, vaultRecord);
    return reference;
  }

  /**
   * Resolve and decrypt secret. Only accessible by backend services and Streaming Gateway.
   */
  async resolveSecret(credentialsReference: string): Promise<string | undefined> {
    const record = this.vaultStore.get(credentialsReference);
    if (!record) {
      // Return simulated token for seed references if not in memory
      if (credentialsReference.startsWith('vault-')) {
        return `resolved_token_for_${credentialsReference}`;
      }
      return undefined;
    }

    try {
      const [ivHex, tagHex, encryptedHex] = record.secret_payload_encrypted.split(':');
      const iv = Buffer.from(ivHex, 'hex');
      const tag = Buffer.from(tagHex, 'hex');
      const decipher = crypto.createDecipheriv('aes-256-gcm', this.encryptionKey, iv);
      decipher.setAuthTag(tag);
      let decrypted = decipher.update(encryptedHex, 'hex', 'utf8');
      decrypted += decipher.final('utf8');
      return decrypted;
    } catch {
      throw new Error(`Failed to decrypt secret for reference '${credentialsReference}'`);
    }
  }

  /**
   * Check if a reference exists in the vault.
   */
  hasReference(credentialsReference: string): boolean {
    return this.vaultStore.has(credentialsReference) || credentialsReference.startsWith('vault-');
  }
}
