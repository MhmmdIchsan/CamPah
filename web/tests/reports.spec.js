import { test, expect } from "@playwright/test";

const suffix = () => `${Date.now()}-${Math.random().toString(36).slice(2, 7)}`;

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

test("user reports, admin status and user management work together", async ({
  page,
  context,
}) => {
  await context.grantPermissions(["geolocation"]);
  await context.setGeolocation({ latitude: -5.55, longitude: 95.32 });
  const unique = suffix();
  const email = `test-${unique}@example.com`;
  const description = `Sampah plastik dekat sungai ${unique}`;
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
  await row.getByRole("combobox").selectOption("Completed");
  await expect(row.locator(".badge")).toHaveText("Completed");
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
  await page
    .getByRole("navigation")
    .getByRole("button", { name: "Laporan", exact: true })
    .click();
  row = page.locator(".report-row").filter({ hasText: unique });
  await expect(row.locator(".badge")).toHaveText("Completed");
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
