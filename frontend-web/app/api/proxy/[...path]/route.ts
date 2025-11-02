import { NextRequest, NextResponse } from 'next/server';

// Use 127.0.0.1 instead of localhost for better server-side connectivity
const getBackendUrl = () => {
  const envUrl = process.env.NEXT_PUBLIC_API_BASE_URL;
  if (envUrl) {
    // Replace localhost with 127.0.0.1 for better server-side connectivity
    return envUrl.replace('localhost', '127.0.0.1');
  }
  return 'http://127.0.0.1:8081';
};

const BACKEND_URL = getBackendUrl();

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ path: string[] }> }
) {
  const { path } = await params;
  return proxyRequest(request, path, 'GET');
}

export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ path: string[] }> }
) {
  const { path } = await params;
  return proxyRequest(request, path, 'POST');
}

export async function PUT(
  request: NextRequest,
  { params }: { params: Promise<{ path: string[] }> }
) {
  const { path } = await params;
  return proxyRequest(request, path, 'PUT');
}

export async function PATCH(
  request: NextRequest,
  { params }: { params: Promise<{ path: string[] }> }
) {
  const { path } = await params;
  return proxyRequest(request, path, 'PATCH');
}

export async function DELETE(
  request: NextRequest,
  { params }: { params: Promise<{ path: string[] }> }
) {
  const { path } = await params;
  return proxyRequest(request, path, 'DELETE');
}

async function proxyRequest(
  request: NextRequest,
  pathSegments: string[],
  method: string
) {
  try {
    const path = pathSegments.join('/');
    const url = new URL(request.url);
    const queryString = url.searchParams.toString();
    
    // Add /api prefix since backend routes are under /api/v1/...
    const backendUrl = `${BACKEND_URL}/api/${path}${queryString ? `?${queryString}` : ''}`;
    
    // Check content type to determine how to handle the body
    const contentType = request.headers.get('content-type');
    const isFormData = contentType?.includes('multipart/form-data');

    console.log(`[Proxy] ${method} ${backendUrl}`);
    console.log(`[Proxy] Path segments:`, pathSegments);
    console.log(`[Proxy] Content-Type:`, contentType);
    console.log(`[Proxy] Is FormData:`, isFormData);
    console.log(`[Proxy] Using BACKEND_URL: ${BACKEND_URL}`);

    // Get request body if present (for POST, PUT, PATCH)
    let body: any = null;
    
    if (method !== 'GET' && method !== 'DELETE') {
      try {
        if (isFormData) {
          // For file uploads, pass FormData as-is
          body = await request.formData();
        } else {
          // For JSON requests, get text
          body = await request.text();
        }
      } catch (e) {
        // No body
      }
    }

    // Forward headers (excluding browser-specific headers)
    // Since this is a server-to-server request, we don't want to forward Origin, Referer, etc.
    const headers: HeadersInit = {};
    
    // Only set Content-Type for JSON requests (NOT for FormData - fetch will set it automatically with boundary)
    if (method !== 'GET' && method !== 'DELETE' && body && !isFormData) {
      headers['Content-Type'] = 'application/json';
    }
    
    // Only forward specific headers we need (no browser headers like Origin, Referer)
    const forwardedHeaders = ['authorization'];
    request.headers.forEach((value, key) => {
      const lowerKey = key.toLowerCase();
      // Skip browser-specific headers that could trigger CORS
      if (
        lowerKey === 'origin' ||
        lowerKey === 'referer' ||
        lowerKey === 'sec-fetch-site' ||
        lowerKey === 'sec-fetch-mode' ||
        lowerKey === 'sec-fetch-dest' ||
        lowerKey === 'host'
      ) {
        return; // Skip these headers
      }
      
      if (
        forwardedHeaders.includes(lowerKey) ||
        (lowerKey.startsWith('x-') && lowerKey !== 'x-forwarded-host')
      ) {
        headers[key] = value;
      }
    });
    
    console.log(`[Proxy] Headers being sent:`, Object.keys(headers));

    // Use fetch with explicit configuration for Next.js server-side
    const fetchOptions: RequestInit = {
      method,
      headers,
      body,
      // Add cache and other options for Next.js compatibility
      cache: 'no-store',
    };

    console.log(`[Proxy] Attempting ${method} request to: ${backendUrl}`);
    
    const response = await fetch(backendUrl, fetchOptions);

    console.log(`[Proxy] Response status: ${response.status} for ${backendUrl}`);

    const data = await response.text();
    let jsonData;

    try {
      jsonData = JSON.parse(data);
    } catch {
      jsonData = data;
    }

    // Forward important headers from backend (including token refresh)
    const responseHeaders: HeadersInit = {
      'Content-Type': 'application/json',
    };
    
    // Forward X-New-Token for sliding window authentication
    const newToken = response.headers.get('X-New-Token');
    if (newToken) {
      responseHeaders['X-New-Token'] = newToken;
    }

    return NextResponse.json(jsonData, {
      status: response.status,
      headers: responseHeaders,
    });
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : 'Unknown error';
    const errorStack = error instanceof Error ? error.stack : undefined;
    
    // Reconstruct backendUrl for error reporting (in case it failed before assignment)
    const path = pathSegments.join('/');
    const url = new URL(request.url);
    const queryString = url.searchParams.toString();
    const attemptedUrl = `${BACKEND_URL}/api/${path}${queryString ? `?${queryString}` : ''}`;
    
    console.error('[Proxy] Error details:');
    console.error('  Message:', errorMessage);
    console.error('  Backend URL:', BACKEND_URL);
    console.error('  Attempted URL:', attemptedUrl);
    console.error('  Method:', method);
    console.error('  Stack:', errorStack);
    
    return NextResponse.json(
      {
        success: false,
        message: 'Failed to connect to backend server',
        error: errorMessage,
        backend_url: BACKEND_URL,
        attempted_url: attemptedUrl,
        method: method,
        hint: `Backend should be running on ${BACKEND_URL}. Check: 1) Backend is running, 2) Port matches (8081), 3) No firewall blocking`,
      },
      { status: 502 }
    );
  }
}
