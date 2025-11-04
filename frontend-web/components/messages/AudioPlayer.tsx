'use client';

import { useState, useRef, useEffect } from 'react';
import { Play, Pause, Volume2, VolumeX } from 'lucide-react';

interface AudioPlayerProps {
  url: string;
  duration?: number;
}

export default function AudioPlayer({ url, duration: initialDuration = 0 }: AudioPlayerProps) {
  const [isPlaying, setIsPlaying] = useState(false);
  const [currentTime, setCurrentTime] = useState(0);
  const [duration, setDuration] = useState(initialDuration);
  const [playbackRate, setPlaybackRate] = useState(1);
  const [isMuted, setIsMuted] = useState(false);
  const [isLoading, setIsLoading] = useState(false);

  const audioRef = useRef<HTMLAudioElement>(null);
  const progressRef = useRef<HTMLDivElement>(null);

  // ==================== PLAYBACK SPEEDS ====================

  const speeds = [1, 1.5, 2];

  const cycleSpeed = () => {
    const currentIndex = speeds.indexOf(playbackRate);
    const nextIndex = (currentIndex + 1) % speeds.length;
    const newSpeed = speeds[nextIndex];
    
    if (audioRef.current) {
      audioRef.current.playbackRate = newSpeed;
    }
    setPlaybackRate(newSpeed);
    console.log('[AudioPlayer] Playback speed changed to:', newSpeed + 'x');
  };

  // ==================== PLAYBACK CONTROLS ====================

  const togglePlayPause = async () => {
    if (!audioRef.current) return;

    try {
      if (isPlaying) {
        audioRef.current.pause();
        setIsPlaying(false);
      } else {
        setIsLoading(true);
        await audioRef.current.play();
        setIsPlaying(true);
        setIsLoading(false);
      }
    } catch (error) {
      console.error('[AudioPlayer] Playback error:', error);
      setIsLoading(false);
      setIsPlaying(false);
    }
  };

  const toggleMute = () => {
    if (audioRef.current) {
      audioRef.current.muted = !isMuted;
      setIsMuted(!isMuted);
    }
  };

  const handleSeek = (e: React.MouseEvent<HTMLDivElement>) => {
    if (!audioRef.current || !progressRef.current) return;

    const rect = progressRef.current.getBoundingClientRect();
    const percent = (e.clientX - rect.left) / rect.width;
    const seekTime = percent * duration;

    audioRef.current.currentTime = seekTime;
    setCurrentTime(seekTime);
  };

  // ==================== AUDIO EVENT LISTENERS ====================

  useEffect(() => {
    const audio = audioRef.current;
    if (!audio) return;

    const handleTimeUpdate = () => {
      setCurrentTime(audio.currentTime);
    };

    const handleDurationChange = () => {
      setDuration(audio.duration);
    };

    const handleEnded = () => {
      setIsPlaying(false);
      setCurrentTime(0);
      audio.currentTime = 0;
    };

    const handleLoadStart = () => {
      setIsLoading(true);
    };

    const handleCanPlay = () => {
      setIsLoading(false);
    };

    const handleError = (e: ErrorEvent) => {
      console.error('[AudioPlayer] Audio error:', e);
      setIsLoading(false);
      setIsPlaying(false);
    };

    audio.addEventListener('timeupdate', handleTimeUpdate);
    audio.addEventListener('durationchange', handleDurationChange);
    audio.addEventListener('ended', handleEnded);
    audio.addEventListener('loadstart', handleLoadStart);
    audio.addEventListener('canplay', handleCanPlay);
    audio.addEventListener('error', handleError as any);

    return () => {
      audio.removeEventListener('timeupdate', handleTimeUpdate);
      audio.removeEventListener('durationchange', handleDurationChange);
      audio.removeEventListener('ended', handleEnded);
      audio.removeEventListener('loadstart', handleLoadStart);
      audio.removeEventListener('canplay', handleCanPlay);
      audio.removeEventListener('error', handleError as any);
    };
  }, []);

  // Set playback rate when speed changes
  useEffect(() => {
    if (audioRef.current) {
      audioRef.current.playbackRate = playbackRate;
    }
  }, [playbackRate]);

  // ==================== HELPERS ====================

  const formatTime = (seconds: number): string => {
    if (!isFinite(seconds)) return '0:00';
    
    const mins = Math.floor(seconds / 60);
    const secs = Math.floor(seconds % 60);
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  };

  const getProgress = (): number => {
    if (!duration || !isFinite(duration)) return 0;
    return (currentTime / duration) * 100;
  };

  // ==================== RENDER ====================

  return (
    <div className="flex items-center gap-2 py-2 min-w-[250px] md:min-w-[320px]">
      {/* Hidden Audio Element */}
      <audio
        ref={audioRef}
        src={url}
        preload="metadata"
        className="hidden"
      />

      {/* Play/Pause Button */}
      <button
        onClick={togglePlayPause}
        disabled={isLoading}
        className="p-2 bg-white/20 hover:bg-white/30 dark:bg-black/20 dark:hover:bg-black/30 rounded-full transition-colors flex-shrink-0"
        title={isPlaying ? 'Pause' : 'Play'}
      >
        {isLoading ? (
          <div className="w-4 h-4 border-2 border-current border-t-transparent rounded-full animate-spin" />
        ) : isPlaying ? (
          <Pause className="w-4 h-4" />
        ) : (
          <Play className="w-4 h-4 ml-0.5" />
        )}
      </button>

      {/* Waveform & Progress */}
      <div className="flex-1 min-w-0">
        {/* Progress Bar */}
        <div
          ref={progressRef}
          onClick={handleSeek}
          className="h-1.5 bg-white/20 dark:bg-black/20 rounded-full cursor-pointer mb-1.5 relative overflow-hidden"
        >
          {/* Filled Progress */}
          <div
            className="h-full bg-white dark:bg-purple-400 rounded-full transition-all duration-100"
            style={{ width: `${getProgress()}%` }}
          />
        </div>

        {/* Time Display */}
        <div className="flex items-center justify-between text-[10px]">
          <span className="opacity-75">
            {formatTime(currentTime)} / {formatTime(duration)}
          </span>
        </div>
      </div>

      {/* Playback Speed Button - Bigger & Separated */}
      <button
        onClick={cycleSpeed}
        className="px-3 py-1.5 bg-white/20 hover:bg-white/30 dark:bg-black/20 dark:hover:bg-black/30 rounded-full transition-colors font-semibold text-xs flex-shrink-0 min-w-[45px] text-center"
        title="Change playback speed (1x, 1.5x, 2x)"
      >
        {playbackRate}x
      </button>

      {/* Volume Button */}
      <button
        onClick={toggleMute}
        className="p-1.5 hover:bg-white/20 dark:hover:bg-black/20 rounded-full transition-colors flex-shrink-0"
        title={isMuted ? 'Unmute' : 'Mute'}
      >
        {isMuted ? (
          <VolumeX className="w-4 h-4 opacity-60" />
        ) : (
          <Volume2 className="w-4 h-4 opacity-75" />
        )}
      </button>
    </div>
  );
}
