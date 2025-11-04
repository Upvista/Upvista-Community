'use client';

import { useState } from 'react';
import Image from 'next/image';

interface ImageMessageProps {
  url: string;
  alt: string;
}

export default function ImageMessage({ url, alt }: ImageMessageProps) {
  const [isModalOpen, setIsModalOpen] = useState(false);

  return (
    <>
      {/* Image Thumbnail */}
      <div
        className="relative rounded-lg overflow-hidden cursor-pointer max-w-xs"
        onClick={() => setIsModalOpen(true)}
      >
        <img
          src={url}
          alt={alt}
          className="w-full h-auto max-h-96 object-cover"
          loading="lazy"
        />
      </div>

      {/* Full Size Modal */}
      {isModalOpen && (
        <div
          className="fixed inset-0 z-50 bg-black/90 flex items-center justify-center p-4"
          onClick={() => setIsModalOpen(false)}
        >
          <button
            onClick={() => setIsModalOpen(false)}
            className="absolute top-4 right-4 text-white text-3xl font-bold hover:text-gray-300"
          >
            ×
          </button>
          <img
            src={url}
            alt={alt}
            className="max-w-full max-h-full object-contain"
          />
        </div>
      )}
    </>
  );
}

