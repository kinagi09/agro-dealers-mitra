/** Backend (Django DateField) expects/returns 'YYYY-MM-DD'. */
export function toApiDateString(date: string): string {
  return date; // <input type="date"> already gives YYYY-MM-DD
}

/** Converts an ISO 'YYYY-MM-DD' string to 'DD-MM-YYYY' for display. */
export function isoToDisplayDateString(isoDate: string): string {
  const [year, month, day] = isoDate.split("-");
  return `${day}-${month}-${year}`;
}
