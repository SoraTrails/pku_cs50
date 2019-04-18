import csv
import os
import urllib.request

from flask import redirect, render_template, request, session
from functools import wraps

def check_stuid(stuid):
    if len(stuid) != 10 or stuid[0] != '1' or not stuid.isdigit():
        return False
    return True

class Reversinator(object):
    def __init__(self, obj):
        self.obj = obj
    def __lt__(self, other):
        return other.obj < self.obj

def apology(message, code=400):
    """Render message as an apology to user."""
    def escape(s):
        """
        Escape special characters.

        https://github.com/jacebrowning/memegen#special-characters
        """
        for old, new in [("-", "--"), (" ", "-"), ("_", "__"), ("?", "~q"),
                         ("%", "~p"), ("#", "~h"), ("/", "~s"), ("\"", "''")]:
            s = s.replace(old, new)
        return s
    return render_template("apology.html", top=code, bottom=escape(message)), code


def login_required(f):
    """
    Decorate routes to require login.

    http://flask.pocoo.org/docs/0.12/patterns/viewdecorators/
    """
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if session.get("user_id") is None:
            return redirect("/login")
        return f(*args, **kwargs)
    return decorated_function



def lookup(symbol, need_name=False, need_price=True):
    """Look up quote for symbol."""
    print("INFO:looking up for {}".format(symbol))

    # Reject symbol if it starts with caret
    if symbol.startswith("^"):
        return None

    # Reject symbol if it contains comma
    if "," in symbol:
        return None

    # Query Alpha Vantage for quote
    # https://www.alphavantage.co/documentation/
    apikey=os.getenv('API_KEY')#3NYODPEK1ISAYN9H
    try:
        price=0
        if need_price:
            # GET CSV

            url = "https://www.alphavantage.co/query?function=TIME_SERIES_INTRADAY&symbol={}&datatype=csv&interval=5min&apikey={}".format(symbol,apikey).strip()
            print("INFO:url = "+url)
            webpage = urllib.request.urlopen(url)

            # Parse CSV
            datareader = csv.reader(webpage.read().decode("utf-8").splitlines())

            # Ignore first row
            next(datareader)

            # Parse second row
            row = next(datareader)

            # Ensure stock exists
            try:
                price = float(row[4])
            except Exception as e:
                print("price error "+str(e))
                return None

        name=""
        if need_name:
            url = "https://www.alphavantage.co/query?function=SYMBOL_SEARCH&keywords={}&datatype=csv&apikey={}".format(symbol,apikey).strip()
            print("INFO:url = "+url)
            webpage = urllib.request.urlopen(url)

            # Parse CSV
            datareader = csv.reader(webpage.read().decode("utf-8").splitlines())

            # Ignore first row
            next(datareader)

            # Parse second row
            row = next(datareader)

            # Ensure name exists
            try:
                name = str(row[1])
            except Exception as e:
                print("name error "+str(e))
                return None

        # Return stock's name (as a str), price (as a float), and (uppercased) symbol (as a str)
        print("INFO:lookup output: "+str(price),name,symbol.upper())
        return {
            "price": price,
            "name": name,
            "symbol": symbol.upper()
        }

    except Exception as e:
        print(e)
        return None


def usd(value):
    """Format value as USD."""
    return "${:,.2f}".format(value)
