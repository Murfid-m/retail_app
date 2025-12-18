// Edge Function: Send Order Confirmation Email using Resend
import "jsr:@supabase/functions-js/edge-runtime.d.ts"

const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY");

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface OrderItem {
  productName: string;
  price: number;
  quantity: number;
}

interface OrderConfirmationRequest {
  email: string;
  name: string;
  orderId: string;
  items: OrderItem[];
  totalAmount: number;
  shippingAddress: string;
}

function formatPrice(price: number): string {
  return price.toFixed(0).replace(/\B(?=(\d{3})+(?!\d))/g, ".");
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { email, name, orderId, items, totalAmount, shippingAddress }: OrderConfirmationRequest = await req.json();

    if (!email || !name || !orderId) {
      return new Response(
        JSON.stringify({ error: "Missing required fields" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Generate order items HTML
    const itemsHtml = items.map((item: OrderItem) => `
      <tr>
        <td style="padding: 12px; border-bottom: 1px solid #eee;">${item.productName}</td>
        <td style="padding: 12px; border-bottom: 1px solid #eee; text-align: center;">${item.quantity}</td>
        <td style="padding: 12px; border-bottom: 1px solid #eee; text-align: right;">Rp ${formatPrice(item.price)}</td>
        <td style="padding: 12px; border-bottom: 1px solid #eee; text-align: right;">Rp ${formatPrice(item.price * item.quantity)}</td>
      </tr>
    `).join("");

    const res = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${RESEND_API_KEY}`,
      },
      body: JSON.stringify({
        from: "Retail App <noreply@enaknih-resto.me>",
        to: [email],
        subject: `Konfirmasi Pesanan #${orderId.substring(0, 8).toUpperCase()} ✅`,
        html: `
          <!DOCTYPE html>
          <html>
          <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
          </head>
          <body style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; padding: 0; background-color: #f4f4f4;">
            <div style="max-width: 600px; margin: 0 auto; background-color: #ffffff;">
              <!-- Header -->
              <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 40px 20px; text-align: center;">
                <h1 style="color: #ffffff; margin: 0; font-size: 28px;">🛍️ Retail App</h1>
                <p style="color: #e8e8e8; margin-top: 10px;">Konfirmasi Pesanan</p>
              </div>
              
              <!-- Success Icon -->
              <div style="text-align: center; padding: 30px 0;">
                <div style="background-color: #4CAF50; width: 80px; height: 80px; border-radius: 50%; margin: 0 auto; display: flex; align-items: center; justify-content: center;">
                  <span style="color: white; font-size: 40px;">✓</span>
                </div>
                <h2 style="color: #333; margin-top: 20px;">Pesanan Berhasil!</h2>
              </div>
              
              <!-- Content -->
              <div style="padding: 20px 30px;">
                <p style="color: #666666; font-size: 16px;">Halo <strong>${name}</strong>,</p>
                <p style="color: #666666; font-size: 16px; line-height: 1.6;">
                  Terima kasih telah berbelanja di Retail App! Pesanan Anda telah kami terima dan sedang diproses.
                </p>
                
                <!-- Order Info -->
                <div style="background-color: #f8f9fa; padding: 15px; border-radius: 8px; margin: 20px 0;">
                  <p style="margin: 0; color: #666;"><strong>No. Pesanan:</strong> #${orderId.substring(0, 8).toUpperCase()}</p>
                  <p style="margin: 10px 0 0; color: #666;"><strong>Tanggal:</strong> ${new Date().toLocaleDateString('id-ID', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' })}</p>
                </div>
                
                <!-- Order Items -->
                <h3 style="color: #333; margin-top: 30px;">Detail Pesanan</h3>
                <table style="width: 100%; border-collapse: collapse; margin-top: 10px;">
                  <thead>
                    <tr style="background-color: #f8f9fa;">
                      <th style="padding: 12px; text-align: left; border-bottom: 2px solid #ddd;">Produk</th>
                      <th style="padding: 12px; text-align: center; border-bottom: 2px solid #ddd;">Qty</th>
                      <th style="padding: 12px; text-align: right; border-bottom: 2px solid #ddd;">Harga</th>
                      <th style="padding: 12px; text-align: right; border-bottom: 2px solid #ddd;">Subtotal</th>
                    </tr>
                  </thead>
                  <tbody>
                    ${itemsHtml}
                  </tbody>
                  <tfoot>
                    <tr>
                      <td colspan="3" style="padding: 15px; text-align: right; font-weight: bold; font-size: 18px;">Total:</td>
                      <td style="padding: 15px; text-align: right; font-weight: bold; font-size: 18px; color: #667eea;">Rp ${formatPrice(totalAmount)}</td>
                    </tr>
                  </tfoot>
                </table>
                
                <!-- Shipping Address -->
                <h3 style="color: #333; margin-top: 30px;">Alamat Pengiriman</h3>
                <div style="background-color: #f8f9fa; padding: 15px; border-radius: 8px; margin-top: 10px;">
                  <p style="margin: 0; color: #666; line-height: 1.6;">
                    📍 ${shippingAddress}
                  </p>
                </div>
                
                <!-- Status Info -->
                <div style="background-color: #fff3cd; padding: 15px; border-radius: 8px; margin-top: 20px; border-left: 4px solid #ffc107;">
                  <p style="margin: 0; color: #856404; font-size: 14px;">
                    <strong>📦 Status:</strong> Pesanan sedang diproses. Anda akan menerima notifikasi saat pesanan dikirim.
                  </p>
                </div>
              </div>
              
              <!-- Footer -->
              <div style="background-color: #f8f8f8; padding: 20px 30px; text-align: center; border-top: 1px solid #eeeeee; margin-top: 30px;">
                <p style="color: #999999; font-size: 12px; margin: 0;">
                  © 2024 Retail App. All rights reserved.
                </p>
                <p style="color: #999999; font-size: 12px; margin-top: 10px;">
                  Jika ada pertanyaan, hubungi customer service kami.
                </p>
              </div>
            </div>
          </body>
          </html>
        `,
      }),
    });

    const data = await res.json();

    if (!res.ok) {
      throw new Error(data.message || "Failed to send email");
    }

    return new Response(
      JSON.stringify({ success: true, message: "Order confirmation email sent!", data }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("Error sending order confirmation:", error);
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
