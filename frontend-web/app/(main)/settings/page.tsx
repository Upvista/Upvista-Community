'use client';

/**
 * Settings Page
 * Created by: Hamza Hafeez - Founder & CEO of Upvista
 * 
 * Complete account management with full backend integration
 * iOS-inspired design with sidebar navigation
 */

import { useState, useEffect } from 'react';
import { MainLayout } from '@/components/layout/MainLayout';
import { Card } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { Avatar } from '@/components/ui/Avatar';
import { Badge } from '@/components/ui/Badge';
import { 
  User, 
  Lock, 
  Shield, 
  Globe, 
  Palette, 
  HelpCircle,
  Upload,
  Trash2,
  AlertTriangle,
  Download,
  Smartphone,
  Eye,
  EyeOff
} from 'lucide-react';
import { useTheme } from '@/lib/contexts/ThemeContext';
import { useUser } from '@/lib/hooks/useUser';
import GenderSelect from '@/components/ui/GenderSelect';
import ProfilePictureEditor from '@/components/profile/ProfilePictureEditor';

const settingsSections = [
  { id: 'account', name: 'Account', icon: User },
  { id: 'security', name: 'Security', icon: Lock },
  { id: 'privacy', name: 'Privacy', icon: Shield },
  { id: 'sessions', name: 'Active Sessions', icon: Smartphone },
  { id: 'data', name: 'Data & Privacy', icon: Download },
  { id: 'appearance', name: 'Appearance', icon: Palette },
  { id: 'language', name: 'Language', icon: Globe },
  { id: 'help', name: 'Help & Support', icon: HelpCircle },
];

export default function SettingsPage() {
  const [activeSection, setActiveSection] = useState('account');

  return (
    <MainLayout>
      <div className="space-y-6">
        <div>
          <h1 className="text-3xl font-bold text-neutral-900 dark:text-neutral-50 mb-2">
            Settings
          </h1>
          <p className="text-base text-neutral-600 dark:text-neutral-400">
            Manage your account settings and preferences
          </p>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-4 gap-6">
          {/* Sidebar Navigation */}
          <Card variant="solid" hoverable={false} className="lg:col-span-1 h-fit">
            <nav className="space-y-1">
              {settingsSections.map((section) => {
                const Icon = section.icon;
                const active = activeSection === section.id;
                
                return (
                  <button
                    key={section.id}
                    onClick={() => setActiveSection(section.id)}
                    className={`
                      w-full flex items-center gap-3 px-4 py-3 rounded-lg text-sm font-medium transition-colors cursor-pointer text-left
                      ${active
                        ? 'bg-brand-purple-100 dark:bg-brand-purple-900/30 text-brand-purple-600 dark:text-brand-purple-400'
                        : 'text-neutral-700 dark:text-neutral-300 hover:bg-neutral-100 dark:hover:bg-neutral-800'
                      }
                    `}
                  >
                    <Icon className="w-5 h-5 flex-shrink-0" />
                    <span className="flex-1">{section.name}</span>
                  </button>
                );
              })}
            </nav>
          </Card>

          {/* Content Area */}
          <div className="lg:col-span-3">
            {activeSection === 'account' && <AccountSection />}
            {activeSection === 'security' && <SecuritySection />}
            {activeSection === 'privacy' && <PrivacySection />}
            {activeSection === 'sessions' && <SessionsSection />}
            {activeSection === 'data' && <DataSection />}
            {activeSection === 'appearance' && <AppearanceSection />}
            {activeSection === 'language' && <LanguageSection />}
            {activeSection === 'help' && <HelpSection />}
          </div>
        </div>
      </div>
    </MainLayout>
  );
}

function AccountSection() {
  const { user, loading, refetch } = useUser();
  const [isLoading, setIsLoading] = useState(false);
  const [message, setMessage] = useState('');
  const [uploadLoading, setUploadLoading] = useState(false);
  const [pictureEditorOpen, setPictureEditorOpen] = useState(false);
  const [emailChangeLoading, setEmailChangeLoading] = useState(false);
  const [usernameChangeLoading, setUsernameChangeLoading] = useState(false);
  
  const [formData, setFormData] = useState({
    display_name: '',
    age: '',
    bio: '',
    location: '',
    gender: '',
    gender_custom: '',
    website: '',
  });

  const [socialLinks, setSocialLinks] = useState({
    twitter: '',
    instagram: '',
    facebook: '',
    linkedin: '',
    github: '',
    youtube: '',
  });

  const [emailData, setEmailData] = useState({
    new_email: '',
    password: '',
    verification_code: '',
  });

  const [emailChangeStep, setEmailChangeStep] = useState<'input' | 'verify'>('input');

  const [usernameData, setUsernameData] = useState({
    new_username: '',
    password: '',
  });

  // Populate form when user data loads
  useEffect(() => {
    if (user) {
      console.log('User data loaded in settings:', user);
      console.log('Social links from user:', user.social_links);
      
      setFormData({
        display_name: user.display_name,
        age: user.age?.toString() || '',
        bio: user.bio || '',
        location: user.location || '',
        gender: user.gender || '',
        gender_custom: user.gender_custom || '',
        website: user.website || '',
      });
      
      // Populate social links
      if (user.social_links) {
        const links = {
          twitter: user.social_links.twitter || '',
          instagram: user.social_links.instagram || '',
          facebook: user.social_links.facebook || '',
          linkedin: user.social_links.linkedin || '',
          github: user.social_links.github || '',
          youtube: user.social_links.youtube || '',
        };
        console.log('Setting social links:', links);
        setSocialLinks(links);
      }
    }
  }, [user]);

  // Update Profile (Basic Profile endpoint)
  const handleUpdateProfile = async () => {
    setIsLoading(true);
    setMessage('');
    
    try {
      const token = localStorage.getItem('token');
      const payload: any = {
        display_name: formData.display_name,
        age: parseInt(formData.age),
        bio: formData.bio || null,
        location: formData.location || null,
        gender: formData.gender || null,
        gender_custom: formData.gender === 'custom' ? formData.gender_custom || null : null,
        website: formData.website || null,
      };

      const response = await fetch('/api/proxy/v1/account/profile/basic', {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`,
        },
        body: JSON.stringify(payload),
      });

      const data = await response.json();
      
      if (response.ok) {
        setMessage('Profile updated successfully!');
        refetch();
      } else {
        setMessage(data.message || 'Failed to update profile');
      }
    } catch (error) {
      setMessage('Network error occurred');
    } finally {
      setIsLoading(false);
    }
  };

  // Upload Profile Picture (called from ProfilePictureEditor after compression)
  const handleProfilePictureUpload = async (compressedFile: File) => {
    setUploadLoading(true);
    setMessage('');
    
    const formData = new FormData();
    formData.append('profile_picture', compressedFile);

    try {
      const token = localStorage.getItem('token');
      const response = await fetch('/api/proxy/v1/account/profile-picture', {
        method: 'POST',
        headers: { 'Authorization': `Bearer ${token}` },
        body: formData,
      });
      
      const data = await response.json();
      
      if (response.ok) {
        setMessage('✓ Profile picture updated successfully! Optimized to ' + (compressedFile.size / 1024).toFixed(2) + ' KB');
        refetch();
      } else {
        throw new Error(data.message || 'Upload failed');
      }
    } catch (error: any) {
      console.error('Upload error:', error);
      throw error; // Re-throw to be caught by the editor
    } finally {
      setUploadLoading(false);
    }
  };

  // Update Social Links
  const handleUpdateSocialLinks = async () => {
    setIsLoading(true);
    setMessage('');
    
    try {
      const token = localStorage.getItem('token');
      const payload = {
        twitter: socialLinks.twitter || null,
        instagram: socialLinks.instagram || null,
        facebook: socialLinks.facebook || null,
        linkedin: socialLinks.linkedin || null,
        github: socialLinks.github || null,
        youtube: socialLinks.youtube || null,
      };

      console.log('Saving social links:', payload);

      const response = await fetch('/api/proxy/v1/account/profile/social-links', {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`,
        },
        body: JSON.stringify(payload),
      });

      const data = await response.json();
      
      if (response.ok) {
        setMessage('✓ Social links updated successfully!');
        refetch();
      } else {
        setMessage(data.message || 'Failed to update social links');
      }
    } catch (error) {
      setMessage('Network error occurred');
    } finally {
      setIsLoading(false);
    }
  };

  // Change Email (Step 1: Request)
  const handleChangeEmail = async () => {
    setEmailChangeLoading(true);
    setMessage('');

    try {
      const token = localStorage.getItem('token');
      const response = await fetch('/api/proxy/v1/account/change-email', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`,
        },
        body: JSON.stringify({
          new_email: emailData.new_email,
          password: emailData.password,
        }),
      });

      const data = await response.json();
      
      if (response.ok) {
        setMessage('Verification code sent to new email! Enter it below to confirm.');
        setEmailChangeStep('verify');
      } else {
        setMessage(data.message || 'Failed to change email');
      }
    } catch (error) {
      setMessage('Network error');
    } finally {
      setEmailChangeLoading(false);
    }
  };

  // Verify Email Change (Step 2: Verify code)
  const handleVerifyEmailChange = async () => {
    if (!emailData.verification_code || emailData.verification_code.length !== 6) {
      setMessage('Please enter a valid 6-digit code');
      return;
    }

    setEmailChangeLoading(true);
    setMessage('');

    try {
      const token = localStorage.getItem('token');
      const response = await fetch('/api/proxy/v1/account/verify-email-change', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`,
        },
        body: JSON.stringify({
          verification_code: emailData.verification_code,
        }),
      });
      
      const data = await response.json();
      
      if (response.ok) {
        setMessage('Email changed successfully!');
        setEmailData({ new_email: '', password: '', verification_code: '' });
        setEmailChangeStep('input');
        refetch();
      } else {
        setMessage(data.message || 'Invalid verification code');
      }
    } catch (error) {
      console.error('Verification error:', error);
      setMessage('Network error');
    } finally {
      setEmailChangeLoading(false);
    }
  };

  // Change Username
  const handleChangeUsername = async () => {
    setUsernameChangeLoading(true);
    setMessage('');

    try {
      const token = localStorage.getItem('token');
      const response = await fetch('/api/proxy/v1/account/change-username', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`,
        },
        body: JSON.stringify({
          new_username: usernameData.new_username,
          password: usernameData.password,
        }),
      });

      const data = await response.json();
      
      if (response.ok) {
        setMessage('Username changed successfully!');
        setUsernameData({ new_username: '', password: '' });
        refetch();
      } else {
        setMessage(data.message || 'Failed to change username');
      }
    } catch (error) {
      setMessage('Network error');
    } finally {
      setUsernameChangeLoading(false);
    }
  };

  if (loading) {
    return (
      <Card variant="solid" hoverable={false}>
        <div className="text-center py-8">
          <div className="animate-spin w-8 h-8 border-4 border-brand-purple-600 border-t-transparent rounded-full mx-auto mb-4"></div>
          <p className="text-neutral-600 dark:text-neutral-400">Loading profile...</p>
        </div>
      </Card>
    );
  }

  return (
    <div className="space-y-6">
      {/* Global Message */}
      {message && (
        <Card variant="solid" hoverable={false} className={`border-2 ${message.includes('success') ? 'border-success bg-green-50 dark:bg-green-950/20' : 'border-error bg-red-50 dark:bg-red-950/20'}`}>
          <p className={`text-sm font-medium ${message.includes('success') ? 'text-success' : 'text-error'}`}>
            {message}
          </p>
        </Card>
      )}

      {/* Profile Picture */}
      <Card variant="solid" hoverable={false}>
        <h3 className="text-lg font-semibold text-neutral-900 dark:text-neutral-50 mb-4">
          Profile Picture
        </h3>
        <div className="flex flex-col md:flex-row items-center md:items-center gap-4 md:gap-6">
          <Avatar 
            src={user?.profile_picture} 
            alt="Profile" 
            fallback={user?.display_name || 'User'} 
            size="3xl" 
          />
          <div className="space-y-2 w-full md:w-auto text-center md:text-left">
            <Button
              variant="primary"
              onClick={() => setPictureEditorOpen(true)}
              disabled={uploadLoading}
              className="w-full md:w-auto text-sm"
            >
              {uploadLoading ? (
                <>
                  <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin"></div>
                  Uploading...
                </>
              ) : (
                <>
                  <Upload className="w-4 h-4" />
                  Edit Photo
                </>
              )}
            </Button>
            <p className="text-xs md:text-sm text-neutral-500 dark:text-neutral-400">
              Up to 5MB • Auto-compressed to ~150KB
            </p>
          </div>
        </div>
      </Card>

      {/* Basic Info */}
      <Card variant="solid" hoverable={false}>
        <h3 className="text-lg font-semibold text-neutral-900 dark:text-neutral-50 mb-4">
          Basic Information
        </h3>
        <div className="space-y-4">
          <Input
            label="Display Name"
            value={formData.display_name}
            onChange={(e) => setFormData({ ...formData, display_name: e.target.value })}
          />
          
          <Input
            label="Age"
            type="number"
            value={formData.age}
            onChange={(e) => setFormData({ ...formData, age: e.target.value })}
          />

          <div>
            <label className="block text-sm font-medium text-neutral-700 dark:text-neutral-300 mb-2">
              Bio (optional)
            </label>
            <textarea
              value={formData.bio}
              onChange={(e) => setFormData({ ...formData, bio: e.target.value })}
              placeholder="Tell us about yourself..."
              maxLength={150}
              rows={3}
              className="w-full px-4 py-3 rounded-xl border border-neutral-200 dark:border-neutral-700 bg-white dark:bg-neutral-900 text-neutral-900 dark:text-neutral-100 placeholder-neutral-400 dark:placeholder-neutral-500 focus:outline-none focus:ring-2 focus:ring-brand-purple-500 resize-none"
            />
            <div className="mt-1 text-xs text-neutral-500 text-right">
              {formData.bio.length} / 150
            </div>
          </div>

          <Input
            label="Location (optional)"
            value={formData.location}
            onChange={(e) => setFormData({ ...formData, location: e.target.value })}
            placeholder="e.g., New York, USA"
          />

          <div>
            <label className="block text-sm font-medium text-neutral-700 dark:text-neutral-300 mb-2">
              Gender (optional)
            </label>
            <GenderSelect
              value={formData.gender}
              customValue={formData.gender_custom}
              onChange={(gender, customValue) => 
                setFormData({ ...formData, gender: gender || '', gender_custom: customValue || '' })
              }
            />
          </div>

          <Input
            label="Website (optional)"
            type="url"
            value={formData.website}
            onChange={(e) => setFormData({ ...formData, website: e.target.value })}
            placeholder="https://yourwebsite.com"
          />

          <Button 
            variant="primary" 
            onClick={handleUpdateProfile}
            isLoading={isLoading}
          >
            Save Changes
          </Button>
        </div>
      </Card>

      {/* Social Links */}
      <Card variant="solid" hoverable={false}>
        <h3 className="text-lg font-semibold text-neutral-900 dark:text-neutral-50 mb-4">
          Social Media Links
        </h3>
        <p className="text-sm text-neutral-600 dark:text-neutral-400 mb-4">
          Connect your social profiles to appear on your public profile page
        </p>
        <div className="space-y-3">
          <Input
            label="X (Twitter) Profile URL"
            type="url"
            value={socialLinks.twitter}
            onChange={(e) => setSocialLinks({ ...socialLinks, twitter: e.target.value })}
            placeholder="https://twitter.com/username"
          />
          
          <Input
            label="Instagram Profile URL"
            type="url"
            value={socialLinks.instagram}
            onChange={(e) => setSocialLinks({ ...socialLinks, instagram: e.target.value })}
            placeholder="https://instagram.com/username"
          />
          
          <Input
            label="Facebook Profile URL"
            type="url"
            value={socialLinks.facebook}
            onChange={(e) => setSocialLinks({ ...socialLinks, facebook: e.target.value })}
            placeholder="https://facebook.com/username"
          />
          
          <Input
            label="LinkedIn Profile URL"
            type="url"
            value={socialLinks.linkedin}
            onChange={(e) => setSocialLinks({ ...socialLinks, linkedin: e.target.value })}
            placeholder="https://linkedin.com/in/username"
          />

          <Input
            label="GitHub Profile URL"
            type="url"
            value={socialLinks.github}
            onChange={(e) => setSocialLinks({ ...socialLinks, github: e.target.value })}
            placeholder="https://github.com/username"
          />

          <Input
            label="YouTube Channel URL"
            type="url"
            value={socialLinks.youtube}
            onChange={(e) => setSocialLinks({ ...socialLinks, youtube: e.target.value })}
            placeholder="https://youtube.com/@username"
          />

          <Button 
            variant="primary" 
            onClick={handleUpdateSocialLinks}
            isLoading={isLoading}
          >
            Save Social Links
          </Button>
        </div>
      </Card>

      {/* Email */}
      <Card variant="solid" hoverable={false}>
        <h3 className="text-lg font-semibold text-neutral-900 dark:text-neutral-50 mb-4">
          Email Address
        </h3>
        <div className="space-y-4">
          <div className="p-3 bg-neutral-100 dark:bg-neutral-800 rounded-lg">
            <p className="text-sm text-neutral-500 dark:text-neutral-400">Current Email</p>
            <p className="text-base font-medium text-neutral-900 dark:text-neutral-50">{user?.email}</p>
          </div>
          
          {emailChangeStep === 'input' ? (
            <>
              <Input
                label="New Email"
                type="email"
                value={emailData.new_email}
                onChange={(e) => setEmailData({ ...emailData, new_email: e.target.value })}
              />
              
              <Input
                label="Password (to confirm)"
                type="password"
                value={emailData.password}
                onChange={(e) => setEmailData({ ...emailData, password: e.target.value })}
              />
              
              <Button 
                variant="secondary" 
                onClick={handleChangeEmail}
                isLoading={emailChangeLoading}
              >
                Send Verification Code
              </Button>
              
              <p className="text-xs text-neutral-500 dark:text-neutral-400">
                We'll send a 6-digit verification code to your new email address
              </p>
            </>
          ) : (
            <>
              <div className="p-4 bg-brand-purple-50 dark:bg-brand-purple-900/20 rounded-lg border border-brand-purple-200 dark:border-brand-purple-800">
                <p className="text-sm font-medium text-brand-purple-700 dark:text-brand-purple-300">
                  Verification code sent to: {emailData.new_email}
                </p>
              </div>
              
              <Input
                label="6-Digit Verification Code"
                type="text"
                maxLength={6}
                value={emailData.verification_code}
                onChange={(e) => setEmailData({ ...emailData, verification_code: e.target.value })}
                placeholder="Enter 6-digit code"
              />
              
              <div className="flex gap-2">
                <Button 
                  variant="primary" 
                  onClick={handleVerifyEmailChange}
                  isLoading={emailChangeLoading}
                >
                  Verify & Change Email
                </Button>
                <Button 
                  variant="ghost" 
                  onClick={() => {
                    setEmailChangeStep('input');
                    setEmailData({ new_email: '', password: '', verification_code: '' });
                    setMessage('');
                  }}
                  disabled={emailChangeLoading}
                >
                  Cancel
                </Button>
              </div>
              
              <p className="text-xs text-neutral-500 dark:text-neutral-400">
                Check your new email inbox for the 6-digit code
              </p>
            </>
          )}
        </div>
      </Card>

      {/* Username */}
      <Card variant="solid" hoverable={false}>
        <h3 className="text-lg font-semibold text-neutral-900 dark:text-neutral-50 mb-4">
          Username
        </h3>
        <div className="space-y-4">
          <div className="p-3 bg-neutral-100 dark:bg-neutral-800 rounded-lg">
            <p className="text-sm text-neutral-500 dark:text-neutral-400">Current Username</p>
            <p className="text-base font-medium text-neutral-900 dark:text-neutral-50">@{user?.username}</p>
          </div>
          
          <Input
            label="New Username"
            value={usernameData.new_username}
            onChange={(e) => setUsernameData({ ...usernameData, new_username: e.target.value })}
          />
          
          <Input
            label="Password (to confirm)"
            type="password"
            value={usernameData.password}
            onChange={(e) => setUsernameData({ ...usernameData, password: e.target.value })}
          />
          
          <Button 
            variant="secondary" 
            onClick={handleChangeUsername}
            isLoading={usernameChangeLoading}
          >
            Change Username
          </Button>
          
          <p className="text-xs text-neutral-500 dark:text-neutral-400">
            Can be changed once every 30 days
          </p>
        </div>
      </Card>

      {/* Profile Picture Editor Modal */}
      <ProfilePictureEditor
        isOpen={pictureEditorOpen}
        onClose={() => setPictureEditorOpen(false)}
        onSave={handleProfilePictureUpload}
        currentImageUrl={user?.profile_picture || null}
      />
    </div>
  );
}

function SecuritySection() {
  const [isLoading, setIsLoading] = useState(false);
  const [message, setMessage] = useState('');
  const [showPasswords, setShowPasswords] = useState({
    current: false,
    new: false,
    confirm: false,
  });
  
  const [passwords, setPasswords] = useState({
    current_password: '',
    new_password: '',
    confirm_password: '',
  });

  const handleChangePassword = async () => {
    if (passwords.new_password !== passwords.confirm_password) {
      setMessage('New passwords do not match');
      return;
    }

    if (passwords.new_password.length < 6) {
      setMessage('Password must be at least 6 characters');
      return;
    }

    setIsLoading(true);
    setMessage('');

    try {
      const token = localStorage.getItem('token');
      const response = await fetch('/api/proxy/v1/account/change-password', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`,
        },
        body: JSON.stringify({
          current_password: passwords.current_password,
          new_password: passwords.new_password,
          confirm_password: passwords.confirm_password,
        }),
      });

      const data = await response.json();
      
      if (response.ok) {
        setMessage('Password changed successfully!');
        setPasswords({ current_password: '', new_password: '', confirm_password: '' });
      } else {
        setMessage(data.message || 'Failed to change password');
      }
    } catch (error) {
      setMessage('Network error');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="space-y-6">
      {message && (
        <Card variant="solid" hoverable={false} className={`border-2 ${message.includes('success') ? 'border-success bg-green-50 dark:bg-green-950/20' : 'border-error bg-red-50 dark:bg-red-950/20'}`}>
          <p className={`text-sm font-medium ${message.includes('success') ? 'text-success' : 'text-error'}`}>
            {message}
          </p>
        </Card>
      )}

      {/* Change Password */}
      <Card variant="solid" hoverable={false}>
        <h3 className="text-lg font-semibold text-neutral-900 dark:text-neutral-50 mb-4">
          Change Password
        </h3>
        <div className="space-y-4">
          <div className="relative">
            <Input 
              label="Current Password" 
              type={showPasswords.current ? "text" : "password"}
              value={passwords.current_password}
              onChange={(e) => setPasswords({ ...passwords, current_password: e.target.value })}
            />
            <button
              type="button"
              onClick={() => setShowPasswords({ ...showPasswords, current: !showPasswords.current })}
              className="absolute right-4 top-4 text-neutral-400 hover:text-neutral-600 dark:hover:text-neutral-300"
            >
              {showPasswords.current ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
            </button>
          </div>
          
          <div className="relative">
            <Input 
              label="New Password" 
              type={showPasswords.new ? "text" : "password"}
              value={passwords.new_password}
              onChange={(e) => setPasswords({ ...passwords, new_password: e.target.value })}
            />
            <button
              type="button"
              onClick={() => setShowPasswords({ ...showPasswords, new: !showPasswords.new })}
              className="absolute right-4 top-4 text-neutral-400 hover:text-neutral-600 dark:hover:text-neutral-300"
            >
              {showPasswords.new ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
            </button>
          </div>
          
          <div className="relative">
            <Input 
              label="Confirm New Password" 
              type={showPasswords.confirm ? "text" : "password"}
              value={passwords.confirm_password}
              onChange={(e) => setPasswords({ ...passwords, confirm_password: e.target.value })}
            />
            <button
              type="button"
              onClick={() => setShowPasswords({ ...showPasswords, confirm: !showPasswords.confirm })}
              className="absolute right-4 top-4 text-neutral-400 hover:text-neutral-600 dark:hover:text-neutral-300"
            >
              {showPasswords.confirm ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
            </button>
          </div>
          
          <Button 
            variant="primary" 
            onClick={handleChangePassword}
            isLoading={isLoading}
          >
            Update Password
          </Button>
        </div>
      </Card>

      {/* Two-Factor Authentication */}
      <Card variant="solid" hoverable={false}>
        <div className="flex items-start justify-between mb-4">
          <div>
            <h3 className="text-lg font-semibold text-neutral-900 dark:text-neutral-50">
              Two-Factor Authentication
            </h3>
            <p className="text-sm text-neutral-600 dark:text-neutral-400 mt-1">
              Add an extra layer of security to your account
            </p>
          </div>
          <Badge variant="neutral">Coming Soon</Badge>
        </div>
        <Button variant="secondary" disabled>Enable 2FA</Button>
      </Card>
    </div>
  );
}

function PrivacySection() {
  const { user, loading, refetch } = useUser();
  const [isLoading, setIsLoading] = useState(false);
  const [message, setMessage] = useState('');
  const [privacyData, setPrivacyData] = useState<{
    profile_privacy: string;
    field_visibility: {
      location: boolean;
      gender: boolean;
      age: boolean;
      website: boolean;
      joined_date: boolean;
      email: boolean;
      [key: string]: boolean;
    };
  }>({
    profile_privacy: 'public',
    field_visibility: {
      location: true,
      gender: true,
      age: true,
      website: true,
      joined_date: true,
      email: false,
    },
  });

  useEffect(() => {
    if (user) {
      setPrivacyData({
        profile_privacy: user.profile_privacy || 'public',
        field_visibility: user.field_visibility || {
          location: true,
          gender: true,
          age: true,
          website: true,
          joined_date: true,
          email: false,
        },
      });
    }
  }, [user]);

  const handleUpdatePrivacy = async () => {
    setIsLoading(true);
    setMessage('');

    try {
      const token = localStorage.getItem('token');
      const response = await fetch('/api/proxy/v1/account/profile/privacy', {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`,
        },
        body: JSON.stringify(privacyData),
      });

      const data = await response.json();
      
      if (response.ok) {
        setMessage('Privacy settings updated successfully!');
        refetch();
      } else {
        setMessage(data.message || 'Failed to update privacy settings');
      }
    } catch (error) {
      setMessage('Network error occurred');
    } finally {
      setIsLoading(false);
    }
  };

  if (loading) {
    return (
      <Card variant="solid" hoverable={false}>
        <div className="text-center py-8">
          <div className="inline-block animate-spin rounded-full h-8 w-8 border-4 border-brand-purple-200 border-t-brand-purple-600"></div>
        </div>
      </Card>
    );
  }

  return (
    <div className="space-y-6">
      {message && (
        <div className={`p-4 rounded-xl ${
          message.includes('success') 
            ? 'bg-green-50 dark:bg-green-900/20 text-green-800 dark:text-green-200' 
            : 'bg-red-50 dark:bg-red-900/20 text-red-800 dark:text-red-200'
        }`}>
          {message}
        </div>
      )}

      <Card variant="solid" hoverable={false}>
        <h3 className="text-lg font-semibold text-neutral-900 dark:text-neutral-50 mb-4">
          Profile Visibility
        </h3>
        <div className="space-y-4">
          <p className="text-sm text-neutral-600 dark:text-neutral-400">
            Choose who can view your profile
          </p>

          <div className="space-y-3">
            {[
              { value: 'public', label: 'Public', description: 'Anyone can view your profile' },
              { value: 'connections', label: 'Connections Only', description: 'Only your connections can view your profile' },
              { value: 'private', label: 'Private', description: 'Only you can view your profile' },
            ].map((option) => (
              <label
                key={option.value}
                className="flex items-start gap-3 p-4 rounded-xl border-2 border-neutral-200 dark:border-neutral-700 cursor-pointer hover:bg-neutral-50 dark:hover:bg-neutral-800 transition-colors"
              >
                <input
                  type="radio"
                  name="profile_privacy"
                  value={option.value}
                  checked={privacyData.profile_privacy === option.value}
                  onChange={(e) => setPrivacyData({ ...privacyData, profile_privacy: e.target.value })}
                  className="mt-1 w-5 h-5 text-brand-purple-600 cursor-pointer"
                />
                <div>
                  <p className="font-medium text-neutral-900 dark:text-neutral-50">{option.label}</p>
                  <p className="text-sm text-neutral-600 dark:text-neutral-400">{option.description}</p>
                </div>
              </label>
            ))}
          </div>
        </div>
      </Card>

      <Card variant="solid" hoverable={false}>
        <h3 className="text-lg font-semibold text-neutral-900 dark:text-neutral-50 mb-4">
          Field Visibility
        </h3>
        <p className="text-sm text-neutral-600 dark:text-neutral-400 mb-4">
          Control which fields are visible on your public profile
        </p>
        
        <div className="space-y-3">
          {[
            { key: 'location', label: 'Location' },
            { key: 'gender', label: 'Gender' },
            { key: 'age', label: 'Age' },
            { key: 'website', label: 'Website' },
            { key: 'joined_date', label: 'Joined Date' },
          ].map((field) => (
            <label
              key={field.key}
              className="flex items-center justify-between p-3 rounded-lg hover:bg-neutral-50 dark:hover:bg-neutral-800 transition-colors cursor-pointer"
            >
              <span className="font-medium text-neutral-900 dark:text-neutral-50">{field.label}</span>
              <input
                type="checkbox"
                checked={privacyData.field_visibility[field.key] || false}
                onChange={(e) => setPrivacyData({
                  ...privacyData,
                  field_visibility: {
                    ...privacyData.field_visibility,
                    [field.key]: e.target.checked,
                  },
                })}
                className="w-5 h-5 text-brand-purple-600 rounded cursor-pointer"
              />
            </label>
          ))}
        </div>

        <div className="mt-6">
          <Button
            variant="primary"
            onClick={handleUpdatePrivacy}
            isLoading={isLoading}
          >
            Save Privacy Settings
          </Button>
        </div>
      </Card>
    </div>
  );
}

function SessionsSection() {
  const [sessions, setSessions] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [message, setMessage] = useState('');
  const [actionLoading, setActionLoading] = useState<string | null>(null);

  useEffect(() => {
    fetchSessions();
  }, []);

  const fetchSessions = async () => {
    try {
      setLoading(true);
      const token = localStorage.getItem('token');
      const response = await fetch('/api/proxy/v1/account/sessions', {
        headers: { 'Authorization': `Bearer ${token}` },
      });

      if (response.ok) {
        const data = await response.json();
        setSessions(data.sessions || []);
      } else {
        setMessage('Failed to fetch sessions');
      }
    } catch (error) {
      setMessage('Network error');
    } finally {
      setLoading(false);
    }
  };

  const handleRevokeSession = async (sessionId: string) => {
    if (!confirm('Are you sure you want to logout from this device?')) return;

    setActionLoading(sessionId);
    try {
      const token = localStorage.getItem('token');
      const response = await fetch(`/api/proxy/v1/account/sessions/${sessionId}`, {
        method: 'DELETE',
        headers: { 'Authorization': `Bearer ${token}` },
      });

      if (response.ok) {
        setMessage('Session revoked successfully');
        fetchSessions();
      } else {
        const data = await response.json();
        setMessage(data.message || 'Failed to revoke session');
      }
    } catch (error) {
      setMessage('Network error');
    } finally {
      setActionLoading(null);
    }
  };

  const handleLogoutAll = async () => {
    if (!confirm('Logout from all devices? You will be logged out.')) return;

    setActionLoading('all');
    try {
      const token = localStorage.getItem('token');
      const response = await fetch('/api/proxy/v1/account/logout-all', {
        method: 'POST',
        headers: { 'Authorization': `Bearer ${token}` },
      });

      if (response.ok) {
        localStorage.removeItem('token');
        window.location.href = '/auth';
      } else {
        const data = await response.json();
        setMessage(data.message || 'Failed to logout');
      }
    } catch (error) {
      setMessage('Network error');
    } finally {
      setActionLoading(null);
    }
  };

  if (loading) {
    return (
      <Card variant="solid" hoverable={false}>
        <div className="text-center py-8">
          <div className="animate-spin w-8 h-8 border-4 border-brand-purple-600 border-t-transparent rounded-full mx-auto mb-4"></div>
          <p className="text-neutral-600 dark:text-neutral-400">Loading sessions...</p>
        </div>
      </Card>
    );
  }

  return (
    <div className="space-y-6">
      {message && (
        <Card variant="solid" hoverable={false} className={`border-2 ${message.includes('success') ? 'border-success bg-green-50 dark:bg-green-950/20' : 'border-error bg-red-50 dark:bg-red-950/20'}`}>
          <p className={`text-sm font-medium ${message.includes('success') ? 'text-success' : 'text-error'}`}>
            {message}
          </p>
        </Card>
      )}

      <Card variant="solid" hoverable={false}>
        <h3 className="text-lg font-semibold text-neutral-900 dark:text-neutral-50 mb-4">
          Active Sessions ({sessions.length})
        </h3>
        
        {sessions.length === 0 ? (
          <p className="text-neutral-600 dark:text-neutral-400 text-center py-8">
            No active sessions found
          </p>
        ) : (
          <div className="space-y-4">
            {sessions.map((session) => (
              <div key={session.id} className="p-4 border border-neutral-200 dark:border-neutral-700 rounded-lg">
                <div className="flex items-start justify-between mb-2">
                  <div className="flex items-start gap-3">
                    <Smartphone className="w-5 h-5 text-neutral-500 mt-1" />
                    <div>
                      <p className="font-medium text-neutral-900 dark:text-neutral-50">
                        {session.device_info || 'Unknown Device'}
                        {session.is_current && (
                          <Badge variant="success" size="sm" className="ml-2">Current</Badge>
                        )}
                      </p>
                      <p className="text-sm text-neutral-600 dark:text-neutral-400">
                        {session.ip_address || 'Unknown IP'}
                      </p>
                      <p className="text-sm text-neutral-500 dark:text-neutral-400">
                        Last active: {new Date(session.created_at).toLocaleString()}
                      </p>
                    </div>
                  </div>
                  {!session.is_current && (
                    <Button 
                      variant="ghost" 
                      size="sm"
                      onClick={() => handleRevokeSession(session.id)}
                      isLoading={actionLoading === session.id}
                    >
                      Revoke
                    </Button>
                  )}
                </div>
              </div>
            ))}
            
            <Button 
              variant="danger" 
              size="sm"
              onClick={handleLogoutAll}
              isLoading={actionLoading === 'all'}
            >
              Logout All Devices
            </Button>
          </div>
        )}
      </Card>
    </div>
  );
}

function DataSection() {
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
        setMessage('Data exported successfully!');
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
    <div className="space-y-6">
      {message && (
        <Card variant="solid" hoverable={false} className={`border-2 ${message.includes('success') ? 'border-success bg-green-50 dark:bg-green-950/20' : 'border-error bg-red-50 dark:bg-red-950/20'}`}>
          <p className={`text-sm font-medium ${message.includes('success') ? 'text-success' : 'text-error'}`}>
            {message}
          </p>
        </Card>
      )}

      {/* Export Data */}
      <Card variant="solid" hoverable={false}>
        <h3 className="text-lg font-semibold text-neutral-900 dark:text-neutral-50 mb-4">
          Export Your Data
        </h3>
        <p className="text-sm text-neutral-600 dark:text-neutral-400 mb-4">
          Download a copy of all your data including posts, profile information, and activity (GDPR compliance).
        </p>
        <Button 
          variant="secondary"
          onClick={handleExportData}
          isLoading={exporting}
        >
          <Download className="w-4 h-4" />
          Request Data Export
        </Button>
      </Card>

      {/* Danger Zone */}
      <Card variant="solid" hoverable={false} className="border-2 border-error/20">
        <div className="flex items-start gap-3 mb-4">
          <AlertTriangle className="w-6 h-6 text-error flex-shrink-0" />
          <div>
            <h3 className="text-lg font-semibold text-error mb-1">
              Danger Zone
            </h3>
            <p className="text-sm text-neutral-600 dark:text-neutral-400">
              Irreversible actions that permanently affect your account
            </p>
          </div>
        </div>
        <div className="space-y-3">
          <Button 
            variant="secondary" 
            className="w-full justify-start"
            onClick={handleDeactivateAccount}
            isLoading={deactivating}
          >
            Deactivate Account
          </Button>
          <Button 
            variant="danger" 
            className="w-full justify-start"
            onClick={handleDeleteAccount}
            isLoading={deleting}
          >
            <Trash2 className="w-4 h-4" />
            Delete Account Permanently
          </Button>
        </div>
      </Card>
    </div>
  );
}

function AppearanceSection() {
  const { theme, setTheme } = useTheme();

  return (
    <Card variant="solid" hoverable={false}>
      <h3 className="text-lg font-semibold text-neutral-900 dark:text-neutral-50 mb-4">
        Appearance
      </h3>
      <div className="space-y-4">
        <div>
          <label className="text-sm font-medium text-neutral-700 dark:text-neutral-300 mb-3 block">
            Theme
          </label>
          <div className="grid grid-cols-3 gap-3">
            {/* Light Theme */}
            <button
              onClick={() => setTheme('light')}
              className={`p-3 rounded-lg border-2 transition-all cursor-pointer ${
                theme === 'light'
                  ? 'border-brand-purple-600 bg-brand-purple-50 dark:bg-brand-purple-900/20'
                  : 'border-neutral-200 dark:border-neutral-700 hover:border-neutral-300 dark:hover:border-neutral-600'
              }`}
            >
              <div className="w-full h-20 bg-white rounded-md mb-2 border border-neutral-200" />
              <p className="font-medium text-neutral-900 dark:text-neutral-50 text-sm">Light</p>
            </button>
            
            {/* Dark Theme */}
            <button
              onClick={() => setTheme('dark')}
              className={`p-3 rounded-lg border-2 transition-all cursor-pointer ${
                theme === 'dark'
                  ? 'border-brand-purple-600 bg-brand-purple-50 dark:bg-brand-purple-900/20'
                  : 'border-neutral-200 dark:border-neutral-700 hover:border-neutral-300 dark:hover:border-neutral-600'
              }`}
            >
              <div className="w-full h-20 bg-neutral-900 rounded-md mb-2 border border-neutral-700" />
              <p className="font-medium text-neutral-900 dark:text-neutral-50 text-sm">Dark</p>
            </button>
            
            {/* iOS Theme */}
            <button
              onClick={() => setTheme('ios')}
              className={`p-3 rounded-lg border-2 transition-all cursor-pointer ${
                theme === 'ios'
                  ? 'border-brand-purple-600 bg-brand-purple-50 dark:bg-brand-purple-900/20'
                  : 'border-neutral-200 dark:border-neutral-700 hover:border-neutral-300 dark:hover:border-neutral-600'
              }`}
            >
              <div className="w-full h-20 rounded-md mb-2 border border-purple-200/40 relative overflow-hidden" 
                style={{
                  background: 'linear-gradient(135deg, #EDE7F6 0%, #D1C4E9 30%, #B39DDB 60%, #9575CD 90%, #7E57C2 100%)',
                }}
              >
                {/* Glossy liquid highlight */}
                <div className="absolute inset-0" 
                  style={{
                    background: 'linear-gradient(135deg, rgba(255,255,255,0.5) 0%, rgba(255,255,255,0.15) 40%, rgba(255,255,255,0) 70%)',
                  }}
                />
              </div>
              <p className="font-medium text-neutral-900 dark:text-neutral-50 text-sm">iOS</p>
            </button>
          </div>
          
          <p className="text-xs text-neutral-500 dark:text-neutral-400 mt-3">
            {theme === 'light' && 'Clean, minimal light theme'}
            {theme === 'dark' && 'Professional dark theme for low-light environments'}
            {theme === 'ios' && '✨ Premium glassmorphism with iOS-inspired design'}
          </p>
        </div>
      </div>
    </Card>
  );
}

function LanguageSection() {
  return (
    <Card variant="solid" hoverable={false}>
      <h3 className="text-lg font-semibold text-neutral-900 dark:text-neutral-50 mb-4">
        Language & Region
      </h3>
      <div className="space-y-4">
        <div>
          <label className="text-sm font-medium text-neutral-700 dark:text-neutral-300 mb-2 block">
            Display Language
          </label>
          <select className="w-full px-4 py-3 rounded-xl border-2 border-neutral-300 dark:border-neutral-700 bg-white dark:bg-neutral-900 cursor-pointer">
            <option>English (US)</option>
            <option>English (UK)</option>
            <option>Spanish</option>
            <option>French</option>
            <option>German</option>
          </select>
        </div>
        <div>
          <label className="text-sm font-medium text-neutral-700 dark:text-neutral-300 mb-2 block">
            Time Zone
          </label>
          <select className="w-full px-4 py-3 rounded-xl border-2 border-neutral-300 dark:border-neutral-700 bg-white dark:bg-neutral-900 cursor-pointer">
            <option>Pacific Time (PT)</option>
            <option>Eastern Time (ET)</option>
            <option>Central Time (CT)</option>
            <option>Mountain Time (MT)</option>
          </select>
        </div>
      </div>
    </Card>
  );
}

function HelpSection() {
  return (
    <div className="space-y-6">
      <Card variant="solid" hoverable={false}>
        <h3 className="text-lg font-semibold text-neutral-900 dark:text-neutral-50 mb-4">
          Help & Support
        </h3>
        <div className="space-y-3">
          <a href="#" className="block p-3 rounded-lg hover:bg-neutral-100 dark:hover:bg-neutral-800 transition-colors cursor-pointer">
            <p className="font-medium text-neutral-900 dark:text-neutral-50">Help Center</p>
            <p className="text-sm text-neutral-600 dark:text-neutral-400">Browse articles and guides</p>
          </a>
          <a href="#" className="block p-3 rounded-lg hover:bg-neutral-100 dark:hover:bg-neutral-800 transition-colors cursor-pointer">
            <p className="font-medium text-neutral-900 dark:text-neutral-50">Contact Support</p>
            <p className="text-sm text-neutral-600 dark:text-neutral-400">Get help from our team</p>
          </a>
          <a href="#" className="block p-3 rounded-lg hover:bg-neutral-100 dark:hover:bg-neutral-800 transition-colors cursor-pointer">
            <p className="font-medium text-neutral-900 dark:text-neutral-50">Report a Problem</p>
            <p className="text-sm text-neutral-600 dark:text-neutral-400">Let us know about issues</p>
          </a>
        </div>
      </Card>

      <Card variant="solid" hoverable={false}>
        <h3 className="text-lg font-semibold text-neutral-900 dark:text-neutral-50 mb-2">
          About Upvista
        </h3>
        <p className="text-sm text-neutral-600 dark:text-neutral-400 mb-4">
          Version 1.0.0 • Built by Hamza Hafeez
        </p>
        <div className="space-y-2 text-sm">
          <a href="#" className="block text-brand-purple-600 dark:text-brand-purple-400 hover:underline cursor-pointer">
            Terms of Service
          </a>
          <a href="#" className="block text-brand-purple-600 dark:text-brand-purple-400 hover:underline cursor-pointer">
            Privacy Policy
          </a>
          <a href="#" className="block text-brand-purple-600 dark:text-brand-purple-400 hover:underline cursor-pointer">
            Community Guidelines
          </a>
        </div>
      </Card>
    </div>
  );
}
