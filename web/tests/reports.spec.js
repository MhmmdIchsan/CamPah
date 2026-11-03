import { test, expect } from "@playwright/test";

const suffix = () => `${Date.now()}-${Math.random().toString(36).slice(2, 7)}`;

test("theme switch is available before login and persists", async ({
  page,
}) => {
  await page.emulateMedia({ colorScheme: "light" });
  await page.goto("/");
  await page.getByRole("button", { name: "Aktifkan mode gelap" }).click();
  await expect(page.locator("html")).toHaveAttribute("data-theme", "dark");
  await page.reload();
  await expect(page.locator("html")).toHaveAttribute("data-theme", "dark");
  await page.getByRole("button", { name: "Aktifkan mode terang" }).click();
  await expect(page.locator("html")).toHaveAttribute("data-theme", "light");
});

async function register(page, email) {
  await page.goto("/");
  await page.getByRole("button", { name: "Daftar sekarang" }).click();
  await page.getByLabel("Nama lengkap").fill("CamPah Browser Tester");
  await page.getByLabel("Email", { exact: true }).fill(email);
  await page.getByLabel("Kata sandi", { exact: true }).fill("TestPassword123");
  await page.getByRole("button", { name: "Tampilkan kata sandi" }).click();
  await expect(page.getByLabel("Kata sandi", { exact: true })).toHaveAttribute(
    "type",
    "text",
  );
  await page.getByRole("button", { name: "Sembunyikan kata sandi" }).click();
  await page.getByRole("button", { name: "Daftar", exact: true }).click();
  await expect(
    page.getByRole("heading", { name: "Dashboard", exact: true }),
  ).toBeVisible();
}

test("dark theme remains usable in the dashboard and report form", async ({
  page,
}) => {
  await page.emulateMedia({ colorScheme: "light" });
  await register(page, `theme-${suffix()}@example.com`);
  await page.getByRole("button", { name: "Aktifkan mode gelap" }).click();
  await expect(page.locator("html")).toHaveAttribute("data-theme", "dark");
  await expect(page.locator(".stat").first()).toHaveCSS(
    "background-color",
    "rgb(28, 48, 41)",
  );
  await page
    .getByRole("navigation")
    .getByRole("button", { name: "Buat laporan", exact: true })
    .click();
  await expect(page.getByLabel("Deskripsi")).toBeVisible();
  await expect(page.getByLabel("Deskripsi")).toHaveCSS(
    "color",
    "rgb(230, 243, 232)",
  );
});

test("user reports, admin status and user management work together", async ({
  page,
  context,
}) => {
  await context.grantPermissions(["geolocation"]);
  await context.setGeolocation({ latitude: -5.55, longitude: 95.32 });
  const unique = suffix();
  const email = `test-${unique}@example.com`;
  const description = `Sampah plastik dekat sungai ${unique}. Terdapat tumpukan botol dan kantong plastik berserakan di pinggir jalan dekat tempat sampah yang perlu segera dibersihkan.`;
  await register(page, email);
  await page.screenshot({
    path: "../artifacts/web-dashboard.png",
    fullPage: true,
  });
  await page
    .getByRole("navigation")
    .getByRole("button", { name: "Buat laporan", exact: true })
    .click();
  await page.getByLabel("Deskripsi").fill(description);
  await page
    .getByLabel("Foto sampah")
    .setInputFiles("tests/fixtures/report.png");
  await expect(page.getByAltText("Pratinjau foto laporan")).toBeVisible();
  await page.getByRole("button", { name: "Gunakan lokasi saya" }).click();
  await expect(page.getByLabel("Latitude", { exact: true })).toHaveValue(
    "-5.55",
  );
  await page
    .getByRole("button", { name: "Kirim laporan", exact: true })
    .click();
  let row = page.locator(".report-row").filter({ hasText: description });
  await expect(row).toBeVisible();
  await expect(row.locator(".badge")).toHaveText("Pending");
  await row.getByRole("button", { name: "Ubah", exact: true }).click();
  await page
    .locator(".modal")
    .getByLabel("Deskripsi")
    .fill(`${description} diperbarui`);
  await page.getByRole("button", { name: "Simpan perubahan" }).click();
  await expect(page.locator(".modal")).toHaveCount(0);
  await page
    .getByRole("navigation")
    .getByRole("button", { name: "Dashboard" })
    .click();
  await page.getByRole("button", { name: "Lihat laporan Pending" }).click();
  await expect(page.getByLabel("Filter status")).toHaveValue("Pending");
  await expect(
    page.locator(".report-row").filter({ hasText: unique }),
  ).toBeVisible();
  await page.getByRole("button", { name: "Keluar" }).click();
  await page.getByLabel("Email", { exact: true }).fill("admin@example.com");
  await page
    .getByLabel("Kata sandi", { exact: true })
    .fill("TestAdminPassword123");
  await page.getByRole("button", { name: "Masuk", exact: true }).click();
  await page
    .getByRole("navigation")
    .getByRole("button", { name: "Laporan", exact: true })
    .click();
  await page.getByRole("textbox", { name: "Cari laporan" }).fill(unique);
  row = page.locator(".report-row").filter({ hasText: unique });
  await expect(row).toHaveCount(1);
  await page.setViewportSize({ width: 320, height: 800 });
  await row.getByRole("button", { name: "Lihat detail" }).click();
  const detail = page.getByRole("dialog", { name: /Detail laporan/ });
  await expect(detail).toContainText("CamPah Browser Tester");
  await detail.getByText("Tinjau kategori AI").click();
  await detail
    .getByLabel("Kategori hasil tinjauan")
    .selectOption("Paper Waste");
  await detail
    .getByLabel("Alasan peninjauan")
    .fill("Terlihat kertas pada foto");
  await detail.getByRole("button", { name: "Simpan tinjauan" }).click();
  await expect(
    detail.getByText("Kategori hasil tinjauan:", { exact: false }),
  ).toBeVisible();
  expect(
    await page.evaluate(
      () => document.documentElement.scrollWidth <= innerWidth,
    ),
  ).toBeTruthy();
  await detail.getByRole("button", { name: "Mulai tangani" }).click();
  await detail
    .getByLabel("Catatan tindak lanjut")
    .fill("Laporan diteruskan kepada petugas.");
  await detail.getByRole("button", { name: "Simpan tindak lanjut" }).click();
  await expect(
    detail.getByText("Laporan diteruskan kepada petugas."),
  ).toBeVisible();
  await detail.getByRole("button", { name: "Selesaikan laporan" }).click();
  await detail
    .getByLabel("Catatan tindak lanjut")
    .fill("Sampah telah dibersihkan.");
  await detail.getByRole("button", { name: "Simpan tindak lanjut" }).click();
  await expect(detail.getByText("Sampah telah dibersihkan.")).toBeVisible();
  await detail
    .getByLabel("Foto bukti penyelesaian")
    .setInputFiles("tests/fixtures/report.png");
  await detail.getByRole("button", { name: "Unggah bukti" }).click();
  await expect(detail.getByAltText("Foto bukti penyelesaian")).toBeVisible();
  await detail.getByRole("button", { name: "Tutup detail" }).click();
  await page.setViewportSize({ width: 1280, height: 800 });
  await expect(row.locator(".badge")).toHaveText("Completed");
  await page
    .getByRole("navigation")
    .getByRole("button", { name: "Dashboard" })
    .click();
  const recent = page.locator(".recent-item").filter({ hasText: unique });
  await expect(recent.locator(".badge")).toHaveText("Completed");
  for (const width of [1280, 320]) {
    await page.setViewportSize({ width, height: 800 });
    const card = await page
      .locator(".recent-item")
      .filter({ hasText: unique })
      .boundingBox();
    const badge = await recent.locator(".badge").boundingBox();
    const title = await recent.locator(".recent-copy strong").boundingBox();
    expect(badge.x + badge.width).toBeLessThanOrEqual(card.x + card.width + 1);
    expect(title.x + title.width).toBeLessThanOrEqual(badge.x);
    expect(
      await page.evaluate(
        () => document.documentElement.scrollWidth <= innerWidth,
      ),
    ).toBeTruthy();
  }
  await page.setViewportSize({ width: 1280, height: 800 });
  await page
    .getByRole("navigation")
    .getByRole("button", { name: "Pengguna", exact: true })
    .click();
  const user = page.locator(".user-row").filter({ hasText: email });
  await user.getByRole("button", { name: "Ubah nama" }).click();
  await page
    .getByRole("dialog")
    .getByLabel("Nama", { exact: true })
    .fill("Updated Browser Tester");
  await page.getByRole("button", { name: "Simpan nama" }).click();
  await expect(user).toContainText("Updated Browser Tester");
  await page.getByRole("button", { name: "Keluar" }).click();
  await page.getByLabel("Email", { exact: true }).fill(email);
  await page.getByLabel("Kata sandi", { exact: true }).fill("TestPassword123");
  await page.getByRole("button", { name: "Masuk", exact: true }).click();
  await expect(
    page.getByRole("heading", { name: "Dashboard", exact: true }),
  ).toBeVisible();
  await page.getByRole("button", { name: "Notifikasi" }).click();
  const notifications = page.getByRole("dialog", { name: "Notifikasi" });
  await expect(
    notifications.getByText(/Sampah telah dibersihkan/),
  ).toBeVisible();
  await notifications.getByText(/Sampah telah dibersihkan/).click();
  await expect(
    page.getByRole("dialog", { name: /Detail laporan/ }),
  ).toBeVisible();
  await page.getByRole("button", { name: "Tutup detail" }).click();
  await page
    .getByRole("navigation")
    .getByRole("button", { name: "Laporan", exact: true })
    .click();
  row = page.locator(".report-row").filter({ hasText: unique });
  await expect(row.locator(".badge")).toHaveText("Completed");
  await row.getByRole("button", { name: "Lihat detail" }).click();
  await expect(
    page
      .getByRole("dialog", { name: /Detail laporan/ })
      .getByText("Sampah telah dibersihkan."),
  ).toBeVisible();
  await expect(
    page
      .getByRole("dialog", { name: /Detail laporan/ })
      .getByAltText("Foto bukti penyelesaian"),
  ).toBeVisible();
  await page.getByRole("button", { name: "Tutup detail" }).click();
  await expect(
    row.getByRole("button", { name: "Ubah", exact: true }),
  ).toHaveCount(0);
  await expect(
    row.getByRole("button", { name: "Hapus", exact: true }),
  ).toHaveCount(0);
});

test("new report form remains usable on a narrow screen", async ({ page }) => {
  await page.setViewportSize({ width: 320, height: 700 });
  await register(page, `narrow-${suffix()}@example.com`);
  await page
    .getByRole("navigation")
    .getByRole("button", { name: "Buat laporan" })
    .click();
  await page
    .getByLabel("Foto sampah")
    .setInputFiles("tests/fixtures/report.png");
  await expect(page.getByAltText("Pratinjau foto laporan")).toBeVisible();
  await page.getByLabel("Deskripsi").fill("Laporan sampah di sekitar jalan.");
  await page.getByLabel("Latitude").fill("-5.55");
  await page.getByLabel("Longitude").fill("95.32");
  expect(
    await page.evaluate(
      () => document.documentElement.scrollWidth > window.innerWidth,
    ),
  ).toBe(false);
  await page.getByRole("button", { name: "Kirim laporan" }).click();
  await expect(
    page
      .locator(".report-row")
      .filter({ hasText: "Laporan sampah di sekitar jalan." }),
  ).toBeVisible();
});

test("corrupt saved session recovers and mobile layout fits the viewport", async ({
  page,
}) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await page.addInitScript(() =>
    localStorage.setItem("campah-session", "invalid-json"),
  );
  await register(page, `mobile-${suffix()}@example.com`);
  await page.screenshot({
    path: "../artifacts/web-mobile.png",
    fullPage: true,
  });
  await expect(
    page
      .getByRole("navigation")
      .getByRole("button", { name: "Laporan", exact: true }),
  ).toBeVisible();
  const overflow = await page.evaluate(
    () => document.documentElement.scrollWidth > window.innerWidth,
  );
  expect(overflow).toBe(false);
});

test("expired authentication clears the session and returns to login", async ({
  page,
}) => {
  await register(page, `expired-${suffix()}@example.com`);
  await page.addInitScript(() => {
    const session = JSON.parse(localStorage.getItem("campah-session"));
    session.access_token = "expired-or-invalid-token";
    localStorage.setItem("campah-session", JSON.stringify(session));
  });
  await page.reload();
  await expect(
    page.getByRole("heading", { name: "Masuk ke akun Anda" }),
  ).toBeVisible();
  await expect
    .poll(() => page.evaluate(() => localStorage.getItem("campah-session")))
    .toBeNull();
});
