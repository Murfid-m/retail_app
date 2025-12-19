import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY") || "re_NS5ahFnC_9SN89ZJm6ruthZDYxLGPVMnZ";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") || "https://rynlfumkxecgngslxdwr.supabase.co";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface LowStockProduct {
  productName: string;
  currentStock: number;
  category: string;
}

serve(async (req) => {
  // Handle CORS preflight request
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { products } = await req.json() as { products: LowStockProduct[] };

    if (!products || products.length === 0) {
      return new Response(
        JSON.stringify({ error: "No products provided" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Get all admin emails from database
    const supabaseResponse = await fetch(`${SUPABASE_URL}/rest/v1/users?is_admin=eq.true&select=email,name`, {
      headers: {
        "apikey": SUPABASE_SERVICE_ROLE_KEY || "",
        "Authorization": `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
        "Content-Type": "application/json",
      },
    });

    const admins = await supabaseResponse.json();
    console.log("Found admins:", admins);

    if (!admins || admins.length === 0) {
      return new Response(
        JSON.stringify({ error: "No admin users found" }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const adminEmails = admins.map((admin: { email: string }) => admin.email);

    // Build product list HTML
    const productListHtml = products.map(product => `
      <tr>
        <td style="padding: 12px; border-bottom: 1px solid #eee;">${product.productName}</td>
        <td style="padding: 12px; border-bottom: 1px solid #eee;">${product.category}</td>
        <td style="padding: 12px; border-bottom: 1px solid #eee; text-align: center;">
          <span style="background-color: ${product.currentStock <= 0 ? '#dc3545' : product.currentStock <= 3 ? '#ffc107' : '#28a745'}; 
                       color: ${product.currentStock <= 3 ? '#000' : '#fff'}; 
                       padding: 4px 12px; border-radius: 12px; font-weight: bold;">
            ${product.currentStock}
          </span>
        </td>
        <td style="padding: 12px; border-bottom: 1px solid #eee; text-align: center;">
          ${product.currentStock <= 0 
            ? '<span style="color: #dc3545; font-weight: bold;">⚠️ HABIS</span>' 
            : '<span style="color: #ffc107; font-weight: bold;">⚠️ RENDAH</span>'}
        </td>
      </tr>
    `).join('');

    const emailHtml = `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
      </head>
      <body style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
        <div style="background: linear-gradient(135deg, #dc3545 0%, #c82333 100%); padding: 30px; text-align: center; border-radius: 10px 10px 0 0;">
          <h1 style="color: white; margin: 0; font-size: 24px;">⚠️ Peringatan Stok Rendah</h1>
          <p style="color: rgba(255,255,255,0.9); margin: 10px 0 0 0;">Beberapa produk memerlukan perhatian Anda</p>
        </div>
        
        <div style="background-color: #f8f9fa; padding: 30px; border-radius: 0 0 10px 10px;">
          <div style="background-color: #fff3cd; border: 1px solid #ffc107; padding: 15px; border-radius: 8px; margin-bottom: 20px;">
            <p style="margin: 0; color: #856404;">
              <strong>🔔 Perhatian:</strong> ${products.length} produk memiliki stok ≤ 3 unit dan perlu segera di-restock.
            </p>
          </div>

          <table style="width: 100%; border-collapse: collapse; background-color: white; border-radius: 8px; overflow: hidden; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">
            <thead>
              <tr style="background-color: #FFC20E;">
                <th style="padding: 12px; text-align: left; color: #000;">Nama Produk</th>
                <th style="padding: 12px; text-align: left; color: #000;">Kategori</th>
                <th style="padding: 12px; text-align: center; color: #000;">Stok</th>
                <th style="padding: 12px; text-align: center; color: #000;">Status</th>
              </tr>
            </thead>
            <tbody>
              ${productListHtml}
            </tbody>
          </table>

          <div style="margin-top: 25px; text-align: center;">
            <p style="color: #666; font-size: 14px;">
              Segera tambahkan stok untuk menghindari kehabisan produk.
            </p>
          </div>

          <hr style="border: none; border-top: 1px solid #eee; margin: 25px 0;">
          
          <p style="color: #999; font-size: 12px; text-align: center; margin: 0;">
            Email ini dikirim otomatis oleh sistem Retail App.<br>
            Waktu: ${new Date().toLocaleString('id-ID', { timeZone: 'Asia/Jakarta' })} WIB
          </p>
        </div>
      </body>
      </html>
    `;

    // Send email using Resend
    const resendResponse = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${RESEND_API_KEY}`,
      },
      body: JSON.stringify({
        from: "Retail App <noreply@enaknih-resto.me>",
        to: adminEmails,
        subject: `⚠️ Peringatan: ${products.length} Produk Stok Rendah`,
        html: emailHtml,
      }),
    });

    const resendData = await resendResponse.json();
    console.log("Resend response:", resendData);

    if (!resendResponse.ok) {
      throw new Error(resendData.message || "Failed to send email");
    }

    return new Response(
      JSON.stringify({ 
        success: true, 
        message: "Low stock notification sent",
        sentTo: adminEmails,
        productsCount: products.length,
        emailId: resendData.id
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );

  } catch (error) {
    console.error("Error:", error);
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
