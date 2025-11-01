'use client';

import { useState, Suspense } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import Image from 'next/image';

// Use proxy route to avoid CORS issues in development
const API_BASE_URL = '/api/proxy';

interface VerifyEmailFormData {
  email: string;
  verification_code: string;
}

interface ApiResponse {
  success: boolean;
  message: string;
  token?: string;
  user?: any;
  error?: string;
}

function VerifyEmailContent() {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);
  const router = useRouter();
  const searchParams = useSearchParams();
  
  // Get email from URL params if available (from registration redirect)
  const emailFromUrl = searchParams.get('email') || '';

  const [formData, setFormData] = useState<VerifyEmailFormData>({
    email: emailFromUrl,
    verification_code: '',
  });

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    
    // Only allow 6 digits for verification code
    if (name === 'verification_code') {
      const digitsOnly = value.replace(/\D/g, '').slice(0, 6);
      setFormData({
        ...formData,
        [name]: digitsOnly,
      });
    } else {
      setFormData({
        ...formData,
        [name]: value,
      });
    }
  };

  const handleVerify = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    try {
      const response = await fetch(`${API_BASE_URL}/api/v1/auth/verify-email`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(formData),
      });

      // Check if response is OK before parsing
      if (!response.ok) {
        try {
          const errorData = await response.json();
          setError(errorData.message || errorData.error || `Server error: ${response.status}`);
        } catch {
          setError(`Server error: ${response.status} ${response.statusText}`);
        }
        setLoading(false);
        return;
      }

      const data: ApiResponse = await response.json();

      if (data.success) {
        setSuccess(true);
        
        // Store token if provided
        if (data.token) {
          localStorage.setItem('token', data.token);
        }
        
        // Redirect to home after 2 seconds
        setTimeout(() => {
          router.push('/');
        }, 2000);
      } else {
        setError(data.message || 'Verification failed');
      }
    } catch (err) {
      const errorMessage = err instanceof Error 
        ? `Connection error: ${err.message}. Make sure backend is running.`
        : `Failed to connect to server. Please check if backend is running.`;
      setError(errorMessage);
      console.error('Verify email error:', err);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="flex min-h-screen items-center justify-center bg-white">
      <div className="w-full max-w-md px-8 py-12">
        {/* Logo and Brand */}
        <div className="mb-12 flex flex-col items-center gap-3">
          <Image
            src="/assets/u.png"
            alt="UpVista"
            width={70}
            height={70}
            className="object-contain"
          />
          <h2 className="text-2xl font-bold tracking-tight text-gray-900">
            <span className="bg-gradient-to-r from-purple-600 to-blue-600 bg-clip-text text-transparent">
              Upvista
            </span>{' '}
            Community
          </h2>
        </div>

        {/* Title */}
        <h1 className="mb-3 text-center text-[32px] font-bold text-black">
          Verify your email
        </h1>
        <p className="mb-10 text-center text-base text-gray-600">
          Enter the 6-digit code sent to your email address
        </p>

        {success ? (
          <div className="rounded-2xl border-2 border-green-400 bg-green-50 p-6 text-center">
            <p className="text-base font-semibold text-green-700">
              Email verified successfully. Redirecting to your account...
            </p>
          </div>
        ) : (
          <form onSubmit={handleVerify} className="space-y-5">
            {error && (
              <div className="mb-6 rounded-2xl border-2 border-red-400 bg-red-50 p-4 text-sm font-medium text-red-700">
                {error}
              </div>
            )}

            {/* Email Input with Floating Label */}
            <div className="relative">
              <input
                type="email"
                name="email"
                placeholder=" "
                required
                value={formData.email}
                onChange={handleChange}
                className="peer w-full rounded-2xl border-2 border-blue-500 px-5 py-4 text-base text-gray-900 transition-all focus:border-blue-600 focus:outline-none"
              />
              <label className="absolute -top-3 left-4 bg-white px-2 text-sm font-medium text-blue-600 peer-placeholder-shown:top-4 peer-placeholder-shown:text-base peer-placeholder-shown:text-gray-400 peer-focus:-top-3 peer-focus:text-sm peer-focus:text-blue-600 transition-all">
                Email address
              </label>
            </div>

            {/* Verification Code Input with Floating Label */}
            <div className="relative">
              <input
                type="text"
                name="verification_code"
                placeholder=" "
                required
                maxLength={6}
                minLength={6}
                value={formData.verification_code}
                onChange={handleChange}
                className="peer w-full rounded-2xl border-2 border-blue-500 px-5 py-4 text-center text-2xl tracking-[0.5em] text-gray-900 transition-all focus:border-blue-600 focus:outline-none"
                pattern="[0-9]{6}"
              />
              <label className="absolute -top-3 left-4 bg-white px-2 text-sm font-medium text-blue-600 peer-placeholder-shown:top-4 peer-placeholder-shown:text-base peer-placeholder-shown:text-gray-400 peer-focus:-top-3 peer-focus:text-sm peer-focus:text-blue-600 transition-all">
                Verification code
              </label>
              <p className="mt-2 text-center text-xs text-gray-500">
                Enter the 6-digit code from your email
              </p>
            </div>

            <button
              type="submit"
              disabled={loading || formData.verification_code.length !== 6}
              className="mt-6 w-full cursor-pointer rounded-2xl bg-black px-4 py-4 text-base font-semibold text-white transition-all hover:bg-gray-800 disabled:cursor-not-allowed disabled:opacity-50"
            >
              {loading ? 'Verifying...' : 'Continue'}
            </button>

            <p className="pt-2 text-center text-sm text-gray-700">
              <button
                type="button"
                onClick={() => router.push('/auth')}
                className="cursor-pointer font-semibold text-blue-600 hover:underline"
              >
                Back to sign in
              </button>
            </p>
          </form>
        )}

        {/* Footer Links */}
        <div className="mt-10 flex justify-center gap-4 text-xs text-gray-500">
          <a href="#" className="cursor-pointer transition-colors hover:text-gray-700 hover:underline">
            Terms of Use
          </a>
          <span className="text-gray-300">|</span>
          <a href="#" className="cursor-pointer transition-colors hover:text-gray-700 hover:underline">
            Privacy Policy
          </a>
        </div>
      </div>
    </div>
  );
}

export default function VerifyEmailPage() {
  return (
    <Suspense fallback={
      <div className="flex min-h-screen items-center justify-center bg-white">
        <div className="h-12 w-12 animate-spin rounded-full border-4 border-gray-200 border-t-blue-600"></div>
      </div>
    }>
      <VerifyEmailContent />
    </Suspense>
  );
}
