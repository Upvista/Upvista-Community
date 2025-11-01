'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import Image from 'next/image';

// Use proxy route to avoid CORS issues in development
const API_BASE_URL = '/api/proxy';

interface SignInFormData {
  email_or_username: string;
  password: string;
}

interface SignUpFormData {
  email: string;
  password: string;
  display_name: string;
  username: string;
  age: number;
}

interface ApiResponse {
  success: boolean;
  message: string;
  token?: string;
  user?: any;
  error?: string;
}

export default function AuthPage() {
  const [isSignUp, setIsSignUp] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [showPassword, setShowPassword] = useState(false);
  const router = useRouter();

  const [signInForm, setSignInForm] = useState<SignInFormData>({
    email_or_username: '',
    password: '',
  });

  const [signUpForm, setSignUpForm] = useState<SignUpFormData>({
    email: '',
    password: '',
    display_name: '',
    username: '',
    age: 18,
  });

  const handleSignInChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setSignInForm({
      ...signInForm,
      [e.target.name]: e.target.value,
    });
  };

  const handleSignUpChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.type === 'number' ? parseInt(e.target.value) : e.target.value;
    setSignUpForm({
      ...signUpForm,
      [e.target.name]: value,
    });
  };

  const handleSignIn = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    try {
      const response = await fetch(`${API_BASE_URL}/api/v1/auth/login`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(signInForm),
      });

      // Check if response is OK before parsing
      if (!response.ok) {
        // Try to parse error response
        try {
          const errorData = await response.json();
          setError(errorData.message || errorData.error || `Server error: ${response.status}`);
        } catch {
          setError(`Server error: ${response.status} ${response.statusText}. Backend may not be running on ${API_BASE_URL}`);
        }
        setLoading(false);
        return;
      }

      const data: ApiResponse = await response.json();

      if (data.success && data.token) {
        // Store token in localStorage
        localStorage.setItem('token', data.token);
        // Redirect to home page
        router.push('/');
      } else {
        setError(data.message || 'Login failed');
      }
    } catch (err) {
      const errorMessage = err instanceof Error 
        ? `Connection error: ${err.message}. Make sure backend is running on ${API_BASE_URL}`
        : `Failed to connect to server. Please check if backend is running on ${API_BASE_URL}`;
      setError(errorMessage);
      console.error('Sign in error:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleSignUp = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    try {
      const response = await fetch(`${API_BASE_URL}/api/v1/auth/register`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(signUpForm),
      });

      // Check if response is OK before parsing
      if (!response.ok) {
        // Try to parse error response
        try {
          const errorData = await response.json();
          setError(errorData.message || errorData.error || `Server error: ${response.status}`);
        } catch {
          setError(`Server error: ${response.status} ${response.statusText}. Backend may not be running on ${API_BASE_URL}`);
        }
        setLoading(false);
        return;
      }

      const data: ApiResponse = await response.json();

      if (data.success) {
        // After successful registration, redirect to verify email page
        setError(null);
        router.push(`/auth/verify-email?email=${encodeURIComponent(signUpForm.email)}`);
      } else {
        setError(data.message || data.error || 'Registration failed');
      }
    } catch (err) {
      const errorMessage = err instanceof Error 
        ? `Connection error: ${err.message}. Make sure backend is running on ${API_BASE_URL}`
        : `Failed to connect to server. Please check if backend is running on ${API_BASE_URL}`;
      setError(errorMessage);
      console.error('Sign up error:', err);
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
        <h1 className="mb-10 text-center text-[32px] font-bold text-black">
          {isSignUp ? 'Create your account' : 'Welcome back'}
        </h1>

        {/* Error Message */}
        {error && (
          <div className="mb-6 rounded-lg border border-red-300 bg-red-50 p-4 text-sm text-red-700">
            {error}
          </div>
        )}

        {/* Main Form */}
        {isSignUp ? (
          <form onSubmit={handleSignUp} className="space-y-5">
            {/* Email Input with Floating Label */}
            <div className="relative">
              <input
                type="email"
                name="email"
                placeholder=" "
                required
                value={signUpForm.email}
                onChange={handleSignUpChange}
                className="peer w-full rounded-2xl border-2 border-blue-500 px-5 py-4 text-base text-gray-900 transition-all focus:border-blue-600 focus:outline-none"
              />
              <label className="absolute -top-3 left-4 bg-white px-2 text-sm font-medium text-blue-600 peer-placeholder-shown:top-4 peer-placeholder-shown:text-base peer-placeholder-shown:text-gray-400 peer-focus:-top-3 peer-focus:text-sm peer-focus:text-blue-600 transition-all">
                Email address
              </label>
            </div>

            {/* Username Input with Floating Label */}
            <div className="relative">
              <input
                type="text"
                name="username"
                placeholder=" "
                required
                minLength={3}
                maxLength={20}
                pattern="[a-zA-Z0-9]+"
                value={signUpForm.username}
                onChange={handleSignUpChange}
                className="peer w-full rounded-2xl border-2 border-blue-500 px-5 py-4 text-base text-gray-900 transition-all focus:border-blue-600 focus:outline-none"
              />
              <label className="absolute -top-3 left-4 bg-white px-2 text-sm font-medium text-blue-600 peer-placeholder-shown:top-4 peer-placeholder-shown:text-base peer-placeholder-shown:text-gray-400 peer-focus:-top-3 peer-focus:text-sm peer-focus:text-blue-600 transition-all">
                Username
              </label>
            </div>

            {/* Display Name Input with Floating Label */}
            <div className="relative">
              <input
                type="text"
                name="display_name"
                placeholder=" "
                required
                minLength={2}
                maxLength={50}
                value={signUpForm.display_name}
                onChange={handleSignUpChange}
                className="peer w-full rounded-2xl border-2 border-blue-500 px-5 py-4 text-base text-gray-900 transition-all focus:border-blue-600 focus:outline-none"
              />
              <label className="absolute -top-3 left-4 bg-white px-2 text-sm font-medium text-blue-600 peer-placeholder-shown:top-4 peer-placeholder-shown:text-base peer-placeholder-shown:text-gray-400 peer-focus:-top-3 peer-focus:text-sm peer-focus:text-blue-600 transition-all">
                Display name
              </label>
            </div>

            {/* Age Input with Floating Label */}
            <div className="relative">
              <input
                type="number"
                name="age"
                placeholder=" "
                required
                min={13}
                max={120}
                value={signUpForm.age}
                onChange={handleSignUpChange}
                className="peer w-full rounded-2xl border-2 border-blue-500 px-5 py-4 text-base text-gray-900 transition-all focus:border-blue-600 focus:outline-none"
              />
              <label className="absolute -top-3 left-4 bg-white px-2 text-sm font-medium text-blue-600 peer-placeholder-shown:top-4 peer-placeholder-shown:text-base peer-placeholder-shown:text-gray-400 peer-focus:-top-3 peer-focus:text-sm peer-focus:text-blue-600 transition-all">
                Age
              </label>
            </div>

            {/* Password Input with Floating Label and Toggle */}
            <div className="relative">
              <input
                type={showPassword ? 'text' : 'password'}
                name="password"
                placeholder=" "
                required
                minLength={6}
                value={signUpForm.password}
                onChange={handleSignUpChange}
                className="peer w-full rounded-2xl border-2 border-blue-500 px-5 py-4 pr-12 text-base text-gray-900 transition-all focus:border-blue-600 focus:outline-none"
              />
              <label className="absolute -top-3 left-4 bg-white px-2 text-sm font-medium text-blue-600 peer-placeholder-shown:top-4 peer-placeholder-shown:text-base peer-placeholder-shown:text-gray-400 peer-focus:-top-3 peer-focus:text-sm peer-focus:text-blue-600 transition-all">
                Password
              </label>
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                className="absolute right-4 top-1/2 -translate-y-1/2 cursor-pointer text-gray-500 transition-colors hover:text-gray-700"
              >
                {showPassword ? (
                  <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.88 9.88l-3.29-3.29m7.532 7.532l3.29 3.29M3 3l3.59 3.59m0 0A9.953 9.953 0 0112 5c4.478 0 8.268 2.943 9.543 7a10.025 10.025 0 01-4.132 5.411m0 0L21 21" />
                  </svg>
                ) : (
                  <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                  </svg>
                )}
              </button>
            </div>

            <button
              type="submit"
              disabled={loading}
              className="mt-6 w-full cursor-pointer rounded-2xl bg-black px-4 py-4 text-base font-semibold text-white transition-all hover:bg-gray-800 disabled:cursor-not-allowed disabled:opacity-50"
            >
              {loading ? 'Creating account...' : 'Continue'}
            </button>

            <p className="pt-2 text-center text-sm text-gray-700">
              Already have an account?{' '}
              <button
                type="button"
                onClick={() => {
                  setIsSignUp(false);
                  setError(null);
                  setShowPassword(false);
                }}
                className="cursor-pointer font-semibold text-blue-600 hover:underline"
              >
                Log in
              </button>
            </p>
          </form>
        ) : (
          <form onSubmit={handleSignIn} className="space-y-5">
            {/* Email or Username Input with Floating Label */}
            <div className="relative">
              <input
                type="text"
                name="email_or_username"
                placeholder=" "
                required
                value={signInForm.email_or_username}
                onChange={handleSignInChange}
                className="peer w-full rounded-2xl border-2 border-blue-500 px-5 py-4 text-base text-gray-900 transition-all focus:border-blue-600 focus:outline-none"
              />
              <label className="absolute -top-3 left-4 bg-white px-2 text-sm font-medium text-blue-600 peer-placeholder-shown:top-4 peer-placeholder-shown:text-base peer-placeholder-shown:text-gray-400 peer-focus:-top-3 peer-focus:text-sm peer-focus:text-blue-600 transition-all">
                Email or Username
              </label>
            </div>

            {/* Password Input with Floating Label and Toggle */}
            <div className="relative">
              <input
                type={showPassword ? 'text' : 'password'}
                name="password"
                placeholder=" "
                required
                value={signInForm.password}
                onChange={handleSignInChange}
                className="peer w-full rounded-2xl border-2 border-blue-500 px-5 py-4 pr-12 text-base text-gray-900 transition-all focus:border-blue-600 focus:outline-none"
              />
              <label className="absolute -top-3 left-4 bg-white px-2 text-sm font-medium text-blue-600 peer-placeholder-shown:top-4 peer-placeholder-shown:text-base peer-placeholder-shown:text-gray-400 peer-focus:-top-3 peer-focus:text-sm peer-focus:text-blue-600 transition-all">
                Password
              </label>
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                className="absolute right-4 top-1/2 -translate-y-1/2 cursor-pointer text-gray-500 transition-colors hover:text-gray-700"
              >
                {showPassword ? (
                  <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.88 9.88l-3.29-3.29m7.532 7.532l3.29 3.29M3 3l3.59 3.59m0 0A9.953 9.953 0 0112 5c4.478 0 8.268 2.943 9.543 7a10.025 10.025 0 01-4.132 5.411m0 0L21 21" />
                  </svg>
                ) : (
                  <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                  </svg>
                )}
              </button>
            </div>

            <button
              type="submit"
              disabled={loading}
              className="mt-6 w-full cursor-pointer rounded-2xl bg-black px-4 py-4 text-base font-semibold text-white transition-all hover:bg-gray-800 disabled:cursor-not-allowed disabled:opacity-50"
            >
              {loading ? 'Signing in...' : 'Continue'}
            </button>

            <p className="pt-2 text-center text-sm text-gray-700">
              Don't have an account?{' '}
              <button
                type="button"
                onClick={() => {
                  setIsSignUp(true);
                  setError(null);
                  setShowPassword(false);
                }}
                className="cursor-pointer font-semibold text-blue-600 hover:underline"
              >
                Sign up
              </button>
            </p>
          </form>
        )}

        {/* OR Separator */}
        <div className="relative my-8">
          <div className="absolute inset-0 flex items-center">
            <div className="w-full border-t border-gray-300"></div>
          </div>
          <div className="relative flex justify-center text-sm">
            <span className="bg-white px-4 font-medium text-gray-600">OR</span>
          </div>
        </div>

        {/* Social Login Buttons */}
        <div className="space-y-3">
          <button
            type="button"
            onClick={() => setError('Google authentication coming soon')}
            className="flex w-full cursor-pointer items-center justify-center gap-3 rounded-2xl border-2 border-gray-300 bg-white px-4 py-3.5 text-base font-medium text-gray-900 transition-all hover:border-gray-400 hover:bg-gray-50"
          >
            <div className="flex h-5 w-5 items-center justify-center">
              <Image
                src="/assets/auth/google.jpg"
                alt="Google"
                width={24}
                height={24}
                className="object-contain"
              />
            </div>
            Continue with Google
          </button>

          <button
            type="button"
            onClick={() => setError('Apple authentication coming soon')}
            className="flex w-full cursor-pointer items-center justify-center gap-3 rounded-2xl border-2 border-gray-300 bg-white px-4 py-3.5 text-base font-medium text-gray-900 transition-all hover:border-gray-400 hover:bg-gray-50"
          >
            <div className="flex h-5 w-5 items-center justify-center">
              <Image
                src="/assets/auth/apple.jpg"
                alt="Apple"
                width={24}
                height={24}
                className="object-contain"
              />
            </div>
            Continue with Apple
          </button>

          <button
            type="button"
            onClick={() => setError('Microsoft authentication coming soon')}
            className="flex w-full cursor-pointer items-center justify-center gap-3 rounded-2xl border-2 border-gray-300 bg-white px-4 py-3.5 text-base font-medium text-gray-900 transition-all hover:border-gray-400 hover:bg-gray-50"
          >
            <div className="flex h-5 w-5 items-center justify-center">
              <svg
                className="h-5 w-5"
                viewBox="0 0 23 23"
                fill="none"
                xmlns="http://www.w3.org/2000/svg"
              >
                <path d="M11 0H0v11h11V0z" fill="#F25022" />
                <path d="M23 0H12v11h11V0z" fill="#7FBA00" />
                <path d="M11 12H0v11h11V12z" fill="#00A4EF" />
                <path d="M23 12H12v11h11V12z" fill="#FFB900" />
              </svg>
            </div>
            Continue with Microsoft
          </button>
        </div>

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
