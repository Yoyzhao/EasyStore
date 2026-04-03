from datetime import datetime, timedelta, timezone

# Define UTC+8 timezone
TZ_UTC_8 = timezone(timedelta(hours=8))

def get_now() -> datetime:
    """
    Get current time in UTC+8 (Asia/Shanghai).
    We use this to store all times consistently as local time in the DB.
    """
    return datetime.now(TZ_UTC_8)
