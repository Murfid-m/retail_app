import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY");

Deno.serve(async (req) => {
  // Handle CORS
  if (req.method === "OPTIONS") {
    return new Response(null, {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        "Access-Control-Allow-Headers": "Content-Type, Authorization",
      },
    });
  }

  try {
    const { email, name, verificationCode } = await req.json();

    if (!email || !verificationCode) {
      return new Response(
        JSON.stringify({ error: "Email and verification code are required" }),
        { 
          status: 400,
          headers: { "Content-Type": "application/json" }
        }
      );
    }

    const emailHtml = `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <style>
          body { font-family: 'Segoe UI', Arial, sans-serif; background-color: #f5f5f5; margin: 0; padding: 20px; }
          .container { max-width: 500px; margin: 0 auto; background: white; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 20px rgba(0,0,0,0.1); }
          .header { background: linear-gradient(135deg, #3F51B5 0%, #5C6BC0 100%); color: white; padding: 30px; text-align: center; }
          .header h1 { margin: 0; font-size: 24px; }
          .content { padding: 30px; text-align: center; }
          .code-box { background: linear-gradient(135deg, #E8EAF6 0%, #C5CAE9 100%); border-radius: 12px; padding: 25px; margin: 20px 0; }
          .code { font-size: 36px; font-weight: bold; color: #3F51B5; letter-spacing: 8px; font-family: 'Courier New', monospace; }
          .info { color: #666; font-size: 14px; margin-top: 20px; }
          .warning { background: #FFF3E0; border-left: 4px solid #FF9800; padding: 12px; margin-top: 20px; text-align: left; font-size: 13px; color: #E65100; }
          .footer { background: #f9f9f9; padding: 20px; text-align: center; color: #999; font-size: 12px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>🛍️ Retail App</h1>
          </div>
          <div class="content">
            <h2>Halo, ${name || 'Pelanggan'}! 👋</h2>
            <p>Terima kasih telah mendaftar di Retail App. Masukkan kode verifikasi berikut untuk mengaktifkan akun Anda:</p>
            
            <div class="code-box">
              <div class="code">${verificationCode}</div>
            </div>
            
            <p class="info">Kode ini berlaku selama <strong>15 menit</strong></p>
            
            <div class="warning">
              ⚠️ Jangan bagikan kode ini kepada siapapun. Tim kami tidak akan pernah meminta kode verifikasi Anda.
            </div>
          </div>
          <div class="footer">
            <p>© 2024 Retail App. All rights reserved.</p>
            <p>Email ini dikirim secara otomatis, mohon tidak membalas email ini.</p>
          </div>
        </div>
      </body>
      </html>
    `;

    // Kirim email via Resend API
    const response = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${RESEND_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: "Retail App <noreply@enaknih-resto.me>",
        to: email,
        subject: `${verificationCode} - Kode Verifikasi Retail App`,
        html: emailHtml,
      }),
    });

    const result = await response.json();

    if (!response.ok) {
      console.error("Resend API error:", result);
      return new Response(
        JSON.stringify({ error: "Failed to send email", details: result }),
        { 
          status: 500,
          headers: { 
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*"
          }
        }
      );
    }

    return new Response(
      JSON.stringify({ success: true, messageId: result.id }),
      { 
        status: 200,
        headers: { 
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*"
        }
      }
    );

  } catch (error) {
    console.error("Error:", error);
    return new Response(
      JSON.stringify({ error: error.message }),
      { 
        status: 500,
        headers: { 
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*"
        }
      }
    );
  }
});
