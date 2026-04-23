export const DEMO_ACCOUNT_ID = 1;

export async function apiRequest(path, options = {}) {
  const headers = new Headers({
    'content-type': 'application/json',
  });
  if (options.headers) {
    if (options.headers instanceof Headers) {
      options.headers.forEach((value, key) => headers.set(key, value));
    } else {
      Object.entries(options.headers).forEach(([key, value]) => {
        headers.set(key, value);
      });
    }
  }
  const response = await fetch(path, {
    ...options,
    headers,
  });
  const contentType = response.headers.get('content-type') || '';
  const body = await response.text();
  const data = contentType.includes('application/json') && body ? JSON.parse(body) : null;
  if (!response.ok) {
    throw new Error(data?.error || body.slice(0, 160) || 'request_failed');
  }
  if (!data) {
    throw new Error('api_returned_non_json_response');
  }
  return data;
}

export const currency = new Intl.NumberFormat('en-US', {
  style: 'currency',
  currency: 'USD',
});

export function toNumber(value) {
  return Number.parseFloat(value || '0');
}

export function idempotencyKey(action) {
  return `${action}-${crypto.randomUUID()}`;
}
