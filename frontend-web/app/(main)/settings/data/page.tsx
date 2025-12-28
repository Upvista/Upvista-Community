'use client';

/**
 * Data & Privacy Settings Page
 * Instagram-style: transparent, full-width, no borders
 */

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { MainLayout } from '@/components/layout/MainLayout';
import { Button } from '@/components/ui/Button';
import { ArrowLeft, Download, Trash2, AlertTriangle } from 'lucide-react';

export default function DataSettingsPage() {
  const router = useRouter();
  const [exporting, setExporting] = useState(false);
  const [deactivating, setDeactivating] = useState(false);
  const [deleting, setDeleting] = useState(false);
  const [message, setMessage] = useState('');

  const handleExportData = async () => {
    setExporting(true);
    setMessage('');
    
    try {
      const token = localStorage.getItem('token');
      const response = await fetch('/api/proxy/v1/account/export-data', {
        headers: { 'Authorization': `Bearer ${token}` },
      });

      if (response.ok) {
        const blob = await response.blob();
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `upvista-data-${Date.now()}.json`;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        window.URL.revokeObjectURL(url);
        setMessage('Data exported successfully');
      } else {
        const data = await response.json();
        setMessage(data.message || 'Export failed');
      }
    } catch (error) {
      setMessage('Export failed');
    } finally {
      setExporting(false);
    }
  };

  const handleDeactivateAccount = async () => {
    const confirmed = window.confirm(
      'Deactivate your account? You can reactivate later by logging in.'
    );
    if (!confirmed) return;

    const password = window.prompt('Enter your password to confirm:');
    if (!password) return;

    setDeactivating(true);
    setMessage('');
    
    try {
      const token = localStorage.getItem('token');
      const response = await fetch('/api/proxy/v1/account/deactivate', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`,
        },
        body: JSON.stringify({ password }),
      });

      if (response.ok) {
        alert('Account deactivated. You will be logged out.');
        localStorage.clear();
        window.location.href = '/auth';
      } else {
        const data = await response.json();
        setMessage(data.message || 'Deactivation failed');
      }
    } catch (error) {
      setMessage('Network error');
    } finally {
      setDeactivating(false);
    }
  };

  const handleDeleteAccount = async () => {
    const confirmed = window.confirm(
      'DELETE YOUR ACCOUNT PERMANENTLY?\n\nThis action CANNOT be undone. All your data will be permanently deleted.'
    );
    if (!confirmed) return;

    const password = window.prompt('Enter your password to confirm deletion:');
    if (!password) return;

    setDeleting(true);
    setMessage('');
    
    try {
      const token = localStorage.getItem('token');
      const response = await fetch('/api/proxy/v1/account/delete', {
        method: 'DELETE',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`,
        },
        body: JSON.stringify({ password }),
      });

      if (response.ok) {
        alert('Account deleted permanently. Goodbye!');
        localStorage.clear();
        window.location.href = '/auth';
      } else {
        const data = await response.json();
        setMessage(data.message || 'Deletion failed');
      }
    } catch (error) {
      setMessage('Network error');
    } finally {
      setDeleting(false);
    }
  };

  return (
    <MainLayout>
      <div className="min-h-screen bg-white dark:bg-neutral-950">
        <div className="w-full">
          {/* Header */}
          <div className="flex items-center gap-4 px-4 py-4 border-b border-neutral-200 dark:border-neutral-800">
            <button
              onClick={() => router.push('/settings')}
              className="p-1 -ml-1 rounded-full transition-colors"
            >
              <ArrowLeft className="w-6 h-6 text-neutral-900 dark:text-neutral-50" />
            </button>
            <h1 className="text-xl font-semibold text-neutral-900 dark:text-neutral-50">
              Data & Privacy
            </h1>
          </div>

          {/* Message */}
          {message && (
            <div className={`mx-4 mt-4 p-3 rounded-lg text-sm ${
              message.includes('success') 
                ? 'bg-green-50 dark:bg-green-900/20 text-green-700 dark:text-green-300' 
                : 'bg-red-50 dark:bg-red-900/20 text-red-700 dark:text-red-300'
            }`}>
              {message}
            </div>
          )}

          <div className="w-full">
            {/* Export Data */}
            <div className="px-4 py-6 space-y-4 border-b border-neutral-200 dark:border-neutral-800">
              <div>
                <h3 className="text-base font-semibold text-neutral-900 dark:text-neutral-50 mb-1">
                  Export Your Data
                </h3>
                <p className="text-sm text-neutral-600 dark:text-neutral-400">
                  Download a copy of all your data (GDPR compliance)
                </p>
              </div>
              <Button 
                variant="outline"
                onClick={handleExportData}
                isLoading={exporting}
                className="w-full"
              >
                <Download className="w-4 h-4 mr-2" />
                Request Data Export
              </Button>
            </div>

            {/* Danger Zone */}
            <div className="px-4 py-6 space-y-3">
              <div className="flex items-start gap-3 mb-4">
                <AlertTriangle className="w-5 h-5 text-red-600 dark:text-red-400 flex-shrink-0 mt-0.5" />
                <div>
                  <h3 className="text-base font-semibold text-red-600 dark:text-red-400 mb-1">
                    Danger Zone
                  </h3>
                  <p className="text-sm text-neutral-600 dark:text-neutral-400">
                    Irreversible actions that permanently affect your account
                  </p>
                </div>
              </div>
              <Button 
                variant="outline" 
                onClick={handleDeactivateAccount}
                isLoading={deactivating}
                className="w-full justify-start"
              >
                Deactivate Account
              </Button>
              <Button 
                variant="danger" 
                onClick={handleDeleteAccount}
                isLoading={deleting}
                className="w-full justify-start"
              >
                <Trash2 className="w-4 h-4 mr-2" />
                Delete Account Permanently
              </Button>
            </div>
          </div>
        </div>
      </div>
    </MainLayout>
  );
}
