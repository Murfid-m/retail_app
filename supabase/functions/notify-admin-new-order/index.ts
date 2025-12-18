import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY");
const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

interface OrderItem {
  productName: string;
  price: number;
  quantity: number;
}

interface AdminUser {
  email: string;
  name: string;
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
    const { 
      orderId, 
      customerName, 
      customerEmail, 
      customerPhone,
      items, 
      totalAmount, 
      shippingAddress 
    } = await req.json();

    if (!orderId || !customerName) {
      return new Response(
        JSON.stringify({ error: "OrderId and customerName are required" }),
        { 
          status: 400,
          headers: { "Content-Type": "application/json" }
        }
      );
    }

    // Get all admin users from database
    const supabase = createClient(SUPABASE_URL!, SUPABASE_SERVICE_ROLE_KEY!);
    
    const { data: admins, error: adminError } = await supabase
      .from('users')
      .select('email, name')
      .eq('is_admin', true);

    if (adminError) {
      console.error("Error fetching admins:", adminError);
      return new Response(
        JSON.stringify({ error: "Failed to fetch admin users", details: adminError }),
        { 
          status: 500,
          headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" }
        }
      );
    }

    if (!admins || admins.length === 0) {
      console.log("No admin users found");
      return new Response(
        JSON.stringify({ success: false, message: "No admin users found" }),
        { 
          status: 200,
          headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" }
        }
      );
    }

    console.log(`Found ${admins.length} admin(s):`, admins.map((a: AdminUser) => a.email));

    // Format items list
    const itemsList = items?.map((item: OrderItem, index: number) => `
      <tr>
        <td style="padding: 12px; border-bottom: 1px solid #eee;">${index + 1}</td>
        <td style="padding: 12px; border-bottom: 1px solid #eee;">${item.productName}</td>
        <td style="padding: 12px; border-bottom: 1px solid #eee; text-align: center;">${item.quantity}</td>
        <td style="padding: 12px; border-bottom: 1px solid #eee; text-align: right;">Rp ${item.price.toLocaleString('id-ID')}</td>
        <td style="padding: 12px; border-bottom: 1px solid #eee; text-align: right;">Rp ${(item.price * item.quantity).toLocaleString('id-ID')}</td>
      </tr>
    `).join('') || '';

    const totalItems = items?.reduce((sum: number, item: OrderItem) => sum + item.quantity, 0) || 0;

    const emailHtml = `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <style>
          body { font-family: 'Segoe UI', Arial, sans-serif; background-color: #f5f5f5; margin: 0; padding: 20px; }
          .container { max-width: 650px; margin: 0 auto; background: white; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 20px rgba(0,0,0,0.1); }
          .header { background: linear-gradient(135deg, #E91E63 0%, #F06292 100%); color: white; padding: 30px; text-align: center; }
          .header h1 { margin: 0; font-size: 24px; }
          .alert-box { background: #FFF3E0; border-left: 4px solid #FF9800; padding: 20px; margin: 0; }
          .alert-title { font-size: 20px; font-weight: bold; color: #E65100; margin-bottom: 8px; }
          .content { padding: 30px; }
          .customer-info { background: #E3F2FD; padding: 20px; border-radius: 8px; margin-bottom: 20px; }
          .customer-info h3 { margin: 0 0 15px 0; color: #1565C0; font-size: 16px; }
          .customer-info p { margin: 8px 0; color: #333; font-size: 14px; }
          .customer-info strong { color: #1565C0; }
          table { width: 100%; border-collapse: collapse; margin: 20px 0; }
          th { background: #f5f5f5; padding: 12px; text-align: left; font-size: 13px; color: #666; border-bottom: 2px solid #ddd; }
          .total-row { background: #E8EAF6; font-weight: bold; }
          .total-row td { padding: 15px 12px; font-size: 16px; }
          .shipping-info { background: #F3E5F5; padding: 20px; border-radius: 8px; margin: 20px 0; }
          .shipping-info h4 { margin: 0 0 10px 0; color: #7B1FA2; font-size: 14px; }
          .stats { display: flex; justify-content: space-around; background: #f9f9f9; padding: 15px; border-radius: 8px; margin: 20px 0; }
          .stat-item { text-align: center; }
          .stat-value { font-size: 24px; font-weight: bold; color: #3F51B5; }
          .stat-label { font-size: 12px; color: #666; }
          .footer { background: #f9f9f9; padding: 20px; text-align: center; color: #999; font-size: 12px; }
          .timestamp { color: #999; font-size: 12px; margin-top: 20px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>🛒 Retail App - Admin</h1>
            <p style="margin: 10px 0 0 0; opacity: 0.9;">Notifikasi Pesanan Baru</p>
          </div>
          
          <div class="alert-box">
            <div class="alert-title">🔔 Pesanan Baru Masuk!</div>
            <p style="margin: 0; color: #666;">Ada pesanan baru yang perlu dikonfirmasi.</p>
          </div>
          
          <div class="content">
            <div class="stats">
              <div class="stat-item">
                <div class="stat-value">${totalItems}</div>
                <div class="stat-label">Total Item</div>
              </div>
              <div class="stat-item">
                <div class="stat-value">Rp ${totalAmount?.toLocaleString('id-ID') || '0'}</div>
                <div class="stat-label">Total Pembayaran</div>
              </div>
            </div>
            
            <div class="customer-info">
              <h3>👤 Informasi Pelanggan</h3>
              <p><strong>Nama:</strong> ${customerName}</p>
              <p><strong>Email:</strong> ${customerEmail || '-'}</p>
              <p><strong>Telepon:</strong> ${customerPhone || '-'}</p>
              <p><strong>Order ID:</strong> #${orderId.substring(0, 8).toUpperCase()}</p>
            </div>
            
            <h3 style="color: #333; margin-bottom: 10px;">📦 Detail Pesanan</h3>
            <table>
              <thead>
                <tr>
                  <th>#</th>
                  <th>Produk</th>
                  <th style="text-align: center;">Qty</th>
                  <th style="text-align: right;">Harga</th>
                  <th style="text-align: right;">Subtotal</th>
                </tr>
              </thead>
              <tbody>
                ${itemsList}
                <tr class="total-row">
                  <td colspan="4">Total Pembayaran</td>
                  <td style="text-align: right;">Rp ${totalAmount?.toLocaleString('id-ID') || '0'}</td>
                </tr>
              </tbody>
            </table>
            
            <div class="shipping-info">
              <h4>📍 Alamat Pengiriman</h4>
              <p style="margin: 0; color: #333; font-size: 14px;">${shippingAddress || '-'}</p>
            </div>
            
            <p class="timestamp">Waktu pesanan: ${new Date().toLocaleString('id-ID', { 
              weekday: 'long', 
              year: 'numeric', 
              month: 'long', 
              day: 'numeric',
              hour: '2-digit',
              minute: '2-digit'
            })}</p>
            
            <p style="color: #666; font-size: 14px;">Silakan login ke dashboard admin untuk memproses pesanan ini.</p>
          </div>
          <div class="footer">
            <p>© 2024 Retail App Admin Panel</p>
            <p>Email ini dikirim secara otomatis untuk notifikasi pesanan baru.</p>
          </div>
        </div>
      </body>
      </html>
    `;

    // Send email to ALL admins
    const adminEmails = admins.map((admin: AdminUser) => admin.email);
    
    const response = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${RESEND_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: "Retail App <noreply@enaknih-resto.me>",
        to: adminEmails, // Send to all admin emails
        subject: `🔔 Pesanan Baru! #${orderId.substring(0, 8).toUpperCase()} - ${customerName} (Rp ${totalAmount?.toLocaleString('id-ID') || '0'})`,
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

    console.log(`Email sent to ${adminEmails.length} admin(s):`, adminEmails);

    return new Response(
      JSON.stringify({ 
        success: true, 
        messageId: result.id,
        sentTo: adminEmails,
        adminCount: adminEmails.length
      }),
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
