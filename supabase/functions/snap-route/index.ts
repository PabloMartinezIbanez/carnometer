const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

type RoutePoint = {
  latitude: number;
  longitude: number;
};

type SnapRouteRequest = {
  points: RoutePoint[];
};

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (request.method !== 'POST') {
    return new Response(
      JSON.stringify({ error: 'Method not allowed' }),
      {
        status: 405,
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json',
        },
      },
    );
  }

  const body = (await request.json()) as SnapRouteRequest;
  if (!body.points || body.points.length < 2) {
    return new Response(
      JSON.stringify({ error: 'At least two points are required' }),
      {
        status: 400,
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json',
        },
      },
    );
  }

  const graphHopperApiKey = Deno.env.get('GRAPHHOPPER_API_KEY');
  const baseUrl = Deno.env.get('GRAPHHOPPER_BASE_URL') ?? 'https://graphhopper.com/api/1';
  const rawGeometry = {
    type: 'LineString',
    coordinates: body.points.map((point) => [point.longitude, point.latitude]),
  };

  if (!graphHopperApiKey) {
    return new Response(
      JSON.stringify({
        snappedGeometry: rawGeometry,
        provider: 'raw-fallback',
        warning: 'GRAPHHOPPER_API_KEY is not configured; returning raw geometry.',
      }),
      {
        status: 200,
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json',
        },
      },
    );
  }

  const params = new URLSearchParams({
    profile: 'car',
    points_encoded: 'false',
    key: graphHopperApiKey,
  });

  for (const point of body.points) {
    params.append('point', `${point.latitude},${point.longitude}`);
  }

  const response = await fetch(`${baseUrl}/route?${params.toString()}`, {
    method: 'GET',
  });

  if (!response.ok) {
    const upstreamBody = await response.text();
    return new Response(
      JSON.stringify({
        snappedGeometry: rawGeometry,
        provider: 'raw-fallback',
        warning: 'GraphHopper route request failed; returning raw geometry.',
        upstreamStatus: response.status,
        upstreamBody,
      }),
      {
        status: 200,
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json',
        },
      },
    );
  }

  const payload = await response.json();
  const coordinates = payload.paths?.[0]?.points?.coordinates ?? rawGeometry.coordinates;

  return new Response(
    JSON.stringify({
      snappedGeometry: {
        type: 'LineString',
        coordinates,
      },
      provider: 'graphhopper-route',
    }),
    {
      status: 200,
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/json',
      },
    },
  );
});
