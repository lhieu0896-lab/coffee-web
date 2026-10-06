// Supabase Edge Function: mascot-chat
// Linh vật AI của quán — trả lời khách bằng tiếng Việt, gợi ý món, và có thể
// tự "bỏ vào giỏ hàng" một món khi khách đã chốt bằng cách gọi tool add_to_cart.
//
// Dùng Groq (api.groq.com) — API tương thích chuẩn OpenAI, có function-calling, miễn phí/rất rẻ.
// (Lưu ý: key dạng "gsk_..." là của Groq, khác với Grok/xAI thật — vẫn dùng bình thường.)
//
// Deploy: dán nguyên file này vào Supabase Dashboard → Edge Functions → Deploy a new function
// (đặt tên function là "mascot-chat").
// Cần thêm 1 secret: GROQ_API_KEY = key của bạn (lấy tại https://console.groq.com/keys)
// Project Settings → Edge Functions → Secrets. KHÔNG dán key trực tiếp vào file này.
// SUPABASE_URL / SUPABASE_ANON_KEY đã được Supabase tự cấp sẵn cho mọi Edge Function, không cần khai báo thêm.

import { createClient } from "jsr:@supabase/supabase-js@2";

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const MASCOT_NAME = "Bông";
const GROQ_MODEL = "openai/gpt-oss-20b";

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: CORS_HEADERS });
  }

  try {
    const { message, history, table } = await req.json();
    if (!message || typeof message !== "string") {
      return json({ reply: "Bạn muốn hỏi mình gì vậy? 😊", action: null });
    }

    const apiKey = Deno.env.get("GROQ_API_KEY");
    if (!apiKey) {
      return json({
        reply: "Mình chưa được kết nối trí tuệ AI (thiếu GROQ_API_KEY), bạn báo chủ quán cấu hình giúp mình nha 🙏",
        action: null,
      });
    }

    // Lấy menu còn bán từ DB để gợi ý luôn đúng giá / đúng món đang có.
    // SUPABASE_ANON_KEY (biến mặc định cũ) có thể trống trên project dùng hệ key mới (sb_publishable_...),
    // nên dự phòng bằng chính publishable key công khai của app (an toàn khi lộ ra, RLS vẫn chặn ghi/đọc trái phép).
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY") || "sb_publishable_QxcnrYLgcAkGnHBwIEh4bg_7MIHnvqL",
    );
    const { data: menu, error: menuErr } = await supabase
      .from("menu_items")
      .select("id, name, category, price_m, price_l")
      .eq("available", true);
    if (menuErr) throw menuErr;

    const menuText = (menu ?? [])
      .map((m: any) => `- id="${m.id}" | ${m.name} (${m.category}) | size M: ${m.price_m}đ, size L: ${m.price_l}đ`)
      .join("\n");

    const systemPrompt = `Bạn là "${MASCOT_NAME}", chú mèo linh vật AI dễ thương của quán cà phê "${Deno.env.get("BRAND_NAME") ?? "Quán Nhà F&B"}", xuất hiện ngay trên màn hình gọi món để trò chuyện và tư vấn cho khách đang ngồi tại bàn ${table ?? ""}. Thỉnh thoảng có thể chêm "meow" một cách tự nhiên, không lạm dụng.

Tính cách: thân thiện, vui vẻ, nói chuyện tự nhiên như nhân viên quán, xưng "mình", gọi khách là "bạn", trả lời ngắn gọn (1-3 câu), có thể dùng 1 emoji phù hợp.

Thực đơn hiện có (chỉ được gợi ý/đặt đúng các món trong danh sách này, dùng đúng "id"):
${menuText || "(menu đang trống)"}

Nhiệm vụ:
- Khi khách chưa biết uống gì, hỏi lại 1 câu ngắn để hiểu gu (ngọt/đắng, có đá/không, cà phê/trà/sinh tố...) rồi gợi ý 1-2 món cụ thể có trong thực đơn kèm giá.
- Khi khách đã nói rõ muốn gọi món nào (ví dụ "cho mình 1 ly đó", "đặt giúp mình ly cà phê sữa size L", "ok lấy món đó"), hãy gọi tool add_to_cart với đúng item_id trong danh sách trên, size phù hợp (mặc định "M" nếu khách không nói rõ) và số lượng.
- Không tự thêm món nếu khách chỉ đang hỏi thông tin hoặc còn đang phân vân.
- Không bịa món ngoài danh sách, không bịa giá.
- Nếu khách hỏi ngoài chủ đề quán (thời tiết, chuyện vui...), vẫn trả lời thân thiện ngắn gọn rồi lái lại việc gọi món.`;

    const history_ = Array.isArray(history)
      ? history
          .filter((h: any) => h && typeof h.content === "string" && (h.role === "user" || h.role === "assistant"))
          .map((h: any) => ({ role: h.role, content: h.content }))
      : [];

    const messages = [{ role: "system", content: systemPrompt }, ...history_, { role: "user", content: message }];

    const aiRes = await fetch("https://api.groq.com/openai/v1/chat/completions", {
      method: "POST",
      headers: {
        "content-type": "application/json",
        authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        model: GROQ_MODEL,
        max_tokens: 400,
        messages,
        tools: [
          {
            type: "function",
            function: {
              name: "add_to_cart",
              description: "Thêm một món vào giỏ hàng cho khách khi khách đã chốt muốn gọi món đó.",
              parameters: {
                type: "object",
                properties: {
                  item_id: { type: "string", description: "id của món, lấy đúng trong danh sách thực đơn đã cho." },
                  size: { type: "string", enum: ["M", "L"] },
                  quantity: { type: "integer", minimum: 1, maximum: 20 },
                },
                required: ["item_id", "size", "quantity"],
              },
            },
          },
        ],
        tool_choice: "auto",
      }),
    });

    if (!aiRes.ok) {
      const errText = await aiRes.text();
      console.error("Groq API error", aiRes.status, errText);
      return json({ reply: "Mình đang hơi đơ xíu, bạn hỏi lại giúp mình sau vài giây nha 🙏", action: null });
    }

    const aiData = await aiRes.json();
    const choice = aiData.choices?.[0]?.message;
    let reply = choice?.content?.toString() ?? "";
    let action: Record<string, unknown> | null = null;

    const toolCall = choice?.tool_calls?.find((t: any) => t.function?.name === "add_to_cart");
    if (toolCall) {
      try {
        const args = JSON.parse(toolCall.function.arguments || "{}");
        action = { type: "add_to_cart", ...args };
      } catch (_) {
        // bỏ qua nếu model trả JSON lỗi
      }
    }

    if (!reply.trim()) {
      reply = action ? "Dạ được, mình gọi món này cho bạn luôn nè! 🛒" : "Bạn nói rõ hơn giúp mình nha 😊";
    }

    return json({ reply: reply.trim(), action });
  } catch (e) {
    console.error(e);
    return json({ reply: "Ối, mình gặp chút trục trặc, bạn thử lại giúp mình nha 🙏", action: null });
  }
});

function json(body: unknown) {
  return new Response(JSON.stringify(body), {
    headers: { ...CORS_HEADERS, "content-type": "application/json" },
  });
}
