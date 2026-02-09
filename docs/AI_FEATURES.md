# AI Feature Brainstorming 🧠

**Budget:** ~$10/month (Google AI Credits)  
**Target Model:** Gemini 1.5 Flash (Efficient, low-latency, multimodal)

## 1. Conversation Summaries (Phase 1 Priority) 📝
**Problem:** Order threads can become lengthy with back-and-forth negotiation, shipping updates, and payment confirmations, making it hard to find the current status at a glance.

**Solution:** Add a "Summarize" feature to the order details page.
- **Trigger:** Button click or automatic trigger when thread exceeds X comments.
- **Input:** Full history of comments/messages for a specific order.
- **AI Output:**
  - **Current Status:** (e.g., "Waiting for payment proof")
  - **Pending Action Items:** (e.g., "Kenny needs to approve shipping cost")
  - **Key Decisions:** (e.g., "Agreed to split shipping 50/50")
- **Cost:** Extremely Low (Text-only input/output).

## 2. Smart Invoice & Receipt Verification 🧾
**Problem:** Wholesalers upload "proof of payment" images/PDFs that require manual verification against the order total.

**Solution:** Use Multimodal AI to verify documents.
- **Trigger:** Webhook/Event when a file is uploaded to the `proof_of_payment` field.
- **Input:** Image or PDF of the receipt + Order Total.
- **AI Output:**
  - **Extracted Data:** Amount, Date, Sender Name.
  - **Verification Flag:** ✅ Match / ⚠️ Mismatch (e.g., "Receipt shows $500, Order is $550").
- **Cost:** Low (Flash is very efficient for image processing).

## 3. Japanese Product Translator & Enricher 🇯🇵
**Problem:** The "Supplier (Mimi)" manages Japanese orders. Product names might be in Japanese, lack English descriptions, or miss context about "chase cards."

**Solution:** Auto-enrich product listings upon creation.
- **Trigger:** New product creation or update.
- **Input:** Product Name (Japanese) and/or Product Image.
- **AI Output:**
  - **Translation:** English title.
  - **Context:** "High Value" context (e.g., "This set features the Charizard SAR").
  - **Tags:** Auto-tagging (e.g., "Scarlet & Violet", "Booster Box", "151").
- **Cost:** Low (Per product addition).

## 4. "The Deal Seeker" (Market Analyst) 📉
**Problem:** It is difficult to know if a wholesale price is a "good deal" compared to current market rates without manual research.

**Solution:** A background job that analyzes new listings.
- **Trigger:** Scheduled job or new product listing.
- **Input:** Product Name + Wholesale Price.
- **AI Output:**
  - **Analysis:** Comparison against known retail baseline (or scraped data).
  - **Verdict:** "🔥 Great Deal: 20% below market average" or "⚠️ Warning: Higher than usual markup."
- **Cost:** Low/Medium (Depends on frequency).
