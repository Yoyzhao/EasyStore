/**
 * Format a date string to UTC+8 (Asia/Shanghai) for display.
 * @param dateStr ISO date string or date-like string
 * @returns Formatted date string in YYYY/M/D HH:mm:ss format
 */
export const formatToUTC8 = (dateStr: string | Date): string => {
  if (!dateStr) return '';
  
  let date: Date;
  if (typeof dateStr === 'string') {
    // If the backend returns a naive string (no Z, no offset),
    // and we know it's UTC+8, we should treat it as such.
    // However, if we've unified the backend to return strings with offsets,
    // new Date(dateStr) will parse it correctly as a moment in time.
    date = new Date(dateStr);
  } else {
    date = dateStr;
  }

  // If date is invalid, return empty string
  if (isNaN(date.getTime())) return '';

  return date.toLocaleString('zh-CN', {
    timeZone: 'Asia/Shanghai',
    hour12: false,
    year: 'numeric',
    month: 'numeric',
    day: 'numeric',
    hour: 'numeric',
    minute: 'numeric',
    second: 'numeric'
  }).replace(/\//g, '/').replace(/\s+/, '  '); // Use double space between date and time for better readability
};
