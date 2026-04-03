/**
 * Format a date string to UTC+8 (Asia/Shanghai) for display.
 * @param dateStr ISO date string or date-like string
 * @returns Formatted date string in YYYY/M/D HH:mm:ss format
 */
export const formatToUTC8 = (dateStr: string | Date): string => {
  if (!dateStr) return '';
  
  let date: Date;
  if (typeof dateStr === 'string') {
    // Handle both 'T' and space as separators for naive datetime strings
    const isNaive = (dateStr.includes('T') || dateStr.includes(' ')) && 
                   !dateStr.includes('Z') && 
                   !dateStr.includes('+');
    
    if (isNaive) {
      // Standardize to ISO format (T separator) if it has a space
      const normalizedStr = dateStr.replace(' ', 'T');
      date = new Date(`${normalizedStr}+08:00`);
    } else {
      date = new Date(dateStr);
    }
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
