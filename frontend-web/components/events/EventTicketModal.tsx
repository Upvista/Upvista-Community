'use client';

/**
 * Event Ticket Modal
 * Created by: Hamza Hafeez - Founder & CEO of Upvista
 * 
 * Displays user's event ticket with QR code and details
 */

import { X, Download, Share2, Calendar, MapPin, Clock, Users } from 'lucide-react';
import { Event, EventApplication, eventsAPI } from '@/lib/api/events';
import { getQRCodeUrl } from '@/lib/utils/shareLinks';

interface EventTicketModalProps {
  event: Event;
  application: EventApplication;
  isOpen: boolean;
  onClose: () => void;
}

export default function EventTicketModal({
  event,
  application,
  isOpen,
  onClose,
}: EventTicketModalProps) {
  // Generate QR code URL
  const ticketData = JSON.stringify({
    event_id: event.id,
    ticket_token: application.ticket_token,
    ticket_number: application.ticket_number,
  });
  const qrCodeUrl = getQRCodeUrl(ticketData, 200);

  if (!isOpen) return null;

  const handleDownload = () => {
    // Create a printable ticket
    const printWindow = window.open('', '_blank');
    if (printWindow) {
      printWindow.document.write(`
        <html>
          <head>
            <title>Event Ticket - ${event.title}</title>
            <style>
              body { font-family: Arial, sans-serif; padding: 20px; }
              .ticket { border: 2px dashed #000; padding: 20px; max-width: 500px; }
              .header { text-align: center; margin-bottom: 20px; }
              .qr-code { text-align: center; margin: 20px 0; }
              .details { margin: 20px 0; }
            </style>
          </head>
          <body>
            <div class="ticket">
              <div class="header">
                <h1>${event.title}</h1>
                <p>Ticket Number: ${application.ticket_number}</p>
              </div>
              ${qrCodeUrl ? `<div class="qr-code"><img src="${qrCodeUrl}" alt="QR Code" /></div>` : ''}
              <div class="details">
                <p><strong>Date:</strong> ${eventsAPI.formatEventDate(event.start_date, event.timezone)}</p>
                <p><strong>Time:</strong> ${eventsAPI.formatEventTime(event.start_date, event.timezone)}</p>
                ${event.location_name ? `<p><strong>Location:</strong> ${event.location_name}</p>` : ''}
                <p><strong>Name:</strong> ${application.full_name || 'N/A'}</p>
                <p><strong>Email:</strong> ${application.email || 'N/A'}</p>
              </div>
            </div>
          </body>
        </html>
      `);
      printWindow.document.close();
      printWindow.print();
    }
  };

  const handleShare = async () => {
    if (navigator.share) {
      try {
        await navigator.share({
          title: `My ticket for ${event.title}`,
          text: `Ticket Number: ${application.ticket_number}`,
          url: window.location.href,
        });
      } catch (err) {
        // User cancelled
      }
    } else {
      navigator.clipboard.writeText(`Ticket Number: ${application.ticket_number}\nEvent: ${event.title}`);
      // Show toast
    }
  };

  return (
    <div className="fixed inset-0 z-[300] flex items-center justify-center bg-black/60 p-4">
      <div className="bg-white dark:bg-neutral-950 rounded-2xl w-full max-w-md max-h-[90vh] overflow-y-auto">
        {/* Header */}
        <div className="flex items-center justify-between p-6 border-b border-neutral-200 dark:border-neutral-800">
          <h2 className="text-xl font-semibold text-neutral-900 dark:text-neutral-50">
            Your Ticket
          </h2>
          <button
            onClick={onClose}
            className="p-1 rounded-full hover:bg-neutral-100 dark:hover:bg-neutral-800 transition-colors"
          >
            <X className="w-5 h-5 text-neutral-600 dark:text-neutral-400" />
          </button>
        </div>

        {/* Ticket Content */}
        <div className="p-6 space-y-6">
          {/* Event Info */}
          <div className="text-center">
            <h3 className="text-2xl font-bold text-neutral-900 dark:text-neutral-50 mb-2">
              {event.title}
            </h3>
            <p className="text-sm text-neutral-500 dark:text-neutral-400">
              Ticket Number: {application.ticket_number}
            </p>
          </div>

          {/* QR Code */}
          {qrCodeUrl && (
            <div className="flex justify-center">
              <div className="p-4 bg-white border-2 border-neutral-200 dark:border-neutral-800 rounded-lg">
                <img src={qrCodeUrl} alt="Ticket QR Code" className="w-48 h-48" />
              </div>
            </div>
          )}

          {/* Ticket Details */}
          <div className="space-y-3 border-t border-b border-neutral-200 dark:border-neutral-800 py-4">
            <div className="flex items-center gap-3">
              <Calendar className="w-5 h-5 text-neutral-400" />
              <div>
                <p className="text-xs text-neutral-500 dark:text-neutral-400">Date</p>
                <p className="text-sm font-medium text-neutral-900 dark:text-neutral-50">
                  {eventsAPI.formatEventDate(event.start_date, event.timezone)}
                </p>
              </div>
            </div>

            {!event.is_all_day && (
              <div className="flex items-center gap-3">
                <Clock className="w-5 h-5 text-neutral-400" />
                <div>
                  <p className="text-xs text-neutral-500 dark:text-neutral-400">Time</p>
                  <p className="text-sm font-medium text-neutral-900 dark:text-neutral-50">
                    {eventsAPI.formatEventTime(event.start_date, event.timezone)}
                  </p>
                </div>
              </div>
            )}

            {event.location_name && (
              <div className="flex items-center gap-3">
                <MapPin className="w-5 h-5 text-neutral-400" />
                <div>
                  <p className="text-xs text-neutral-500 dark:text-neutral-400">Location</p>
                  <p className="text-sm font-medium text-neutral-900 dark:text-neutral-50">
                    {event.location_name}
                  </p>
                </div>
              </div>
            )}

            <div className="flex items-center gap-3">
              <Users className="w-5 h-5 text-neutral-400" />
              <div>
                <p className="text-xs text-neutral-500 dark:text-neutral-400">Attendee</p>
                <p className="text-sm font-medium text-neutral-900 dark:text-neutral-50">
                  {application.full_name || 'N/A'}
                </p>
                {application.email && (
                  <p className="text-xs text-neutral-500 dark:text-neutral-400">
                    {application.email}
                  </p>
                )}
              </div>
            </div>
          </div>

          {/* Actions */}
          <div className="flex items-center gap-3">
            <button
              onClick={handleDownload}
              className="flex-1 flex items-center justify-center gap-2 px-4 py-2 border border-neutral-200 dark:border-neutral-800 rounded-lg text-sm font-medium text-neutral-900 dark:text-neutral-50 hover:bg-neutral-50 dark:hover:bg-neutral-900 transition-colors"
            >
              <Download className="w-4 h-4" />
              Download
            </button>
            <button
              onClick={handleShare}
              className="flex-1 flex items-center justify-center gap-2 px-4 py-2 border border-neutral-200 dark:border-neutral-800 rounded-lg text-sm font-medium text-neutral-900 dark:text-neutral-50 hover:bg-neutral-50 dark:hover:bg-neutral-900 transition-colors"
            >
              <Share2 className="w-4 h-4" />
              Share
            </button>
          </div>

          {/* Status Badge */}
          <div className="text-center">
            <span className={`inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-medium ${
              application.status === 'approved'
                ? 'bg-green-100 dark:bg-green-900/30 text-green-600 dark:text-green-400'
                : 'bg-yellow-100 dark:bg-yellow-900/30 text-yellow-600 dark:text-yellow-400'
            }`}>
              {application.status === 'approved' ? '✓ Confirmed' : 'Pending Approval'}
            </span>
          </div>
        </div>
      </div>
    </div>
  );
}
