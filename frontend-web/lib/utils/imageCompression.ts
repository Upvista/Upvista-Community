/**
 * Image Compression Utility
 * Optimizes images for storage efficiency while maintaining quality
 * Created by: Hamza Hafeez - Founder & CEO of Upvista
 */

import imageCompression from 'browser-image-compression';

export interface CompressionOptions {
  maxSizeMB?: number;
  maxWidthOrHeight?: number;
  useWebWorker?: boolean;
  fileType?: string;
  initialQuality?: number;
}

/**
 * Compress profile image to ~100-200 KB with high quality
 * Accepts up to 5 MB, outputs WebP format
 */
export async function compressProfileImage(file: File): Promise<File> {
  const options: CompressionOptions = {
    maxSizeMB: 0.2,              // Target 200 KB max
    maxWidthOrHeight: 1024,      // Max dimension for profile pics
    useWebWorker: true,          // Use web worker for better performance
    fileType: 'image/webp',      // WebP = 70% smaller than JPEG
    initialQuality: 0.85,        // High quality (0.0 - 1.0)
  };

  try {
    const compressed = await imageCompression(file, options);
    
    console.log('Original file:', file.name);
    console.log('Original size:', (file.size / 1024).toFixed(2), 'KB');
    console.log('Compressed size:', (compressed.size / 1024).toFixed(2), 'KB');
    console.log('Compression ratio:', ((1 - compressed.size / file.size) * 100).toFixed(1), '%');
    
    // If compressed file is very small, increase quality slightly
    if (compressed.size < 50000) { // Less than 50 KB
      console.log('File very small, using higher quality...');
      options.initialQuality = 0.9;
      return await imageCompression(file, options);
    }
    
    return compressed;
  } catch (error) {
    console.error('Compression failed:', error);
    throw new Error('Failed to compress image. Please try another image.');
  }
}

/**
 * Create a preview URL from a file for displaying before upload
 */
export function createImagePreview(file: File): Promise<string> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = (e) => resolve(e.target?.result as string);
    reader.onerror = reject;
    reader.readAsDataURL(file);
  });
}

/**
 * Validate image file
 */
export function validateImageFile(file: File, maxSizeMB: number = 5): { valid: boolean; error?: string } {
  // Check if it's an image
  if (!file.type.startsWith('image/')) {
    return { valid: false, error: 'Please select an image file (PNG, JPEG, WebP, etc.)' };
  }

  // Check size before compression
  const maxSizeBytes = maxSizeMB * 1024 * 1024;
  if (file.size > maxSizeBytes) {
    return { valid: false, error: `Image must be less than ${maxSizeMB} MB` };
  }

  // Check if it's a supported format
  const supportedFormats = ['image/jpeg', 'image/png', 'image/webp', 'image/gif', 'image/jpg'];
  if (!supportedFormats.includes(file.type)) {
    return { valid: false, error: 'Supported formats: JPEG, PNG, WebP, GIF' };
  }

  return { valid: true };
}

/**
 * Get optimal compression settings based on image type
 */
export function getCompressionSettings(fileType: string): CompressionOptions {
  const baseSettings: CompressionOptions = {
    maxWidthOrHeight: 1024,
    useWebWorker: true,
    fileType: 'image/webp',
  };

  // For photos/complex images, use slightly lower compression
  if (fileType === 'image/jpeg' || fileType === 'image/jpg') {
    return {
      ...baseSettings,
      maxSizeMB: 0.2,
      initialQuality: 0.85,
    };
  }

  // For PNGs (often graphics/logos), maintain higher quality
  if (fileType === 'image/png') {
    return {
      ...baseSettings,
      maxSizeMB: 0.25,
      initialQuality: 0.9,
    };
  }

  // Default settings
  return {
    ...baseSettings,
    maxSizeMB: 0.2,
    initialQuality: 0.85,
  };
}

