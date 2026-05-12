export function logError(error: unknown): void {
  if (!process.env.KOPI_INK_DEBUG_ERRORS) {
    return
  }

  console.error(error)
}
