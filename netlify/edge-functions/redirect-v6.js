export default async (request, context) => {
  const clientIP = context.ip || "";
  const url = new URL(request.url);

  // Unknown IPs should bypass Scarf.
  const isIPv4 = /^\d{1,3}(?:\.\d{1,3}){3}$/.test(clientIP);

  if (isIPv4) {
    // Use the actual Scarf Gateway domain configured
    // for the Fluentd package.
    url.hostname = "fluentd.gateway.scarf.sh";
  } else {
    // IPv6 or unknown: bypass Scarf.
    url.hostname = "fluentd.cdn.cncf.io";
  }
  //url.protocol = "https";
  //url.port = 443;

  return new Response(null, {
    status: 302,
    headers: {
      Location: url.toString(),
      "Cache-Control": "no-store",
    },
  });
};
