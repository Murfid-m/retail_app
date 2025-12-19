import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY");

interface OrderItem {
  productName: string;
  price: number;
  quantity: number;
}

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
    const { email, name, orderId, status, items, totalAmount, shippingAddress } = await req.json();

    if (!email || !orderId || !status) {
      return new Response(
        JSON.stringify({ error: "Email, orderId, and status are required" }),
        { 
          status: 400,
          headers: { "Content-Type": "application/json" }
        }
      );
    }

    // Status mapping to Indonesian
    const statusMap: Record<string, { label: string; color: string; icon: string; message: string }> = {
      'pending': { 
        label: 'Menunggu Konfirmasi', 
        color: '#FF9800', 
        icon: '⏳',
        message: 'Pesanan Anda sedang menunggu konfirmasi dari admin.'
      },
      'processing': { 
        label: 'Sedang Diproses', 
        color: '#2196F3', 
        icon: '🔄',
        message: 'Pesanan Anda sedang diproses dan akan segera dikirim.'
      },
      'shipped': { 
        label: 'Dalam Pengiriman', 
        color: '#9C27B0', 
        icon: '🚚',
        message: 'Pesanan Anda sedang dalam perjalanan menuju alamat tujuan.'
      },
      'delivered': { 
        label: 'Terkirim', 
        color: '#4CAF50', 
        icon: '✅',
        message: 'Pesanan Anda telah sampai di tujuan. Terima kasih telah berbelanja!'
      },
      'cancelled': { 
        label: 'Dibatalkan', 
        color: '#F44336', 
        icon: '❌',
        message: 'Pesanan Anda telah dibatalkan. Silakan hubungi admin untuk informasi lebih lanjut.'
      },
    };

    const statusInfo = statusMap[status] || { 
      label: status, 
      color: '#757575', 
      icon: '📦',
      message: 'Status pesanan Anda telah diperbarui.'
    };

    // Format items list
    const itemsList = items?.map((item: OrderItem) => `
      <tr>
        <td style="padding: 12px; border-bottom: 1px solid #eee;">${item.productName}</td>
        <td style="padding: 12px; border-bottom: 1px solid #eee; text-align: center;">${item.quantity}</td>
        <td style="padding: 12px; border-bottom: 1px solid #eee; text-align: right;">Rp ${item.price.toLocaleString('id-ID')}</td>
      </tr>
    `).join('') || '';

    const emailHtml = `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <style>
          body { font-family: 'Segoe UI', Arial, sans-serif; background-color: #f5f5f5; margin: 0; padding: 20px; }
          .container { max-width: 600px; margin: 0 auto; background: white; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 20px rgba(0,0,0,0.1); }
          .header { background: linear-gradient(135deg, #3F51B5 0%, #5C6BC0 100%); color: white; padding: 30px; text-align: center; }
          .header h1 { margin: 0; font-size: 24px; }
          .content { padding: 30px; }
          .status-box { background: ${statusInfo.color}15; border-left: 4px solid ${statusInfo.color}; padding: 20px; margin: 20px 0; border-radius: 0 8px 8px 0; }
          .status-label { font-size: 24px; font-weight: bold; color: ${statusInfo.color}; margin-bottom: 8px; }
          .status-message { color: #666; font-size: 14px; }
          .order-info { background: #f9f9f9; padding: 15px; border-radius: 8px; margin: 20px 0; }
          .order-id { font-size: 14px; color: #666; }
          .order-id strong { color: #333; }
          table { width: 100%; border-collapse: collapse; margin: 20px 0; }
          th { background: #f5f5f5; padding: 12px; text-align: left; font-size: 14px; color: #666; }
          .total-row { background: #E8EAF6; font-weight: bold; }
          .total-row td { padding: 15px 12px; }
          .shipping-info { background: #FFF3E0; padding: 15px; border-radius: 8px; margin: 20px 0; }
          .shipping-info h4 { margin: 0 0 8px 0; color: #E65100; font-size: 14px; }
          .footer { background: #f9f9f9; padding: 20px; text-align: center; color: #999; font-size: 12px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>🛍️ Retail App</h1>
            <p style="margin: 10px 0 0 0; opacity: 0.9;">Update Status Pesanan</p>
          </div>
          <div class="content">
            <h2>Halo, ${name || 'Pelanggan'}! 👋</h2>
            
            <div class="status-box">
              <div class="status-label">${statusInfo.icon} ${statusInfo.label}</div>
              <div class="status-message">${statusInfo.message}</div>
            </div>
            
            <div class="order-info">
              <p class="order-id">Order ID: <strong>#${orderId.substring(0, 8).toUpperCase()}</strong></p>
            </div>
            
            ${items && items.length > 0 ? `
            <h3 style="color: #333; margin-bottom: 10px;">Detail Pesanan</h3>
            <table>
              <thead>
                <tr>
                  <th>Produk</th>
                  <th style="text-align: center;">Qty</th>
                  <th style="text-align: right;">Harga</th>
                </tr>
              </thead>
              <tbody>
                ${itemsList}
                <tr class="total-row">
                  <td colspan="2">Total Pembayaran</td>
                  <td style="text-align: right;">Rp ${totalAmount?.toLocaleString('id-ID') || '0'}</td>
                </tr>
              </tbody>
            </table>
            ` : ''}
            
            ${shippingAddress ? `
            <div class="shipping-info">
              <h4>📍 Alamat Pengiriman</h4>
              <p style="margin: 0; color: #666; font-size: 14px;">${shippingAddress}</p>
            </div>
            ` : ''}
            
            <p style="color: #666; font-size: 14px;">Jika ada pertanyaan, silakan hubungi customer service kami.</p>
          </div>
          <div class="footer">
            <p>© 2024 Retail App. All rights reserved.</p>
            <p>Email ini dikirim secara otomatis, mohon tidak membalas email ini.</p>
          </div>
        </div>
      </body>
      </html>
    `;

    // Send email via Resend API
    const response = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${RESEND_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: "Retail App <noreply@enaknih-resto.me>",
        to: email,
        subject: `${statusInfo.icon} Status Pesanan: ${statusInfo.label} - Order #${orderId.substring(0, 8).toUpperCase()}`,
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
            "Access-Control-Allow-Origin": "*",
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
          "Access-Control-Allow-Origin": "*",
        }
      }
    );
  } catch (error) {
    console.error("Error:", error);
    return new Response(
      JSON.stringify({ error: "Internal server error", details: error.message }),
      { 
        status: 500,
        headers: { 
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        }
      }
    );
  }
});
