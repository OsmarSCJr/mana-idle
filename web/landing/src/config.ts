function withoutTrailingSlash(value: string | undefined): string {
  return value?.trim().replace(/\/+$/, "") ?? "";
}

export const siteConfig = Object.freeze({
  apiUrl: withoutTrailingSlash(import.meta.env.VITE_API_URL),
  downloadUrl: import.meta.env.VITE_DOWNLOAD_URL?.trim() ?? "",
  privacyEmail:
    import.meta.env.VITE_PRIVACY_EMAIL?.trim() || "privacidade@manaidle.com",
});
