import os
import sys
import time
from functools import wraps
import click
import requests
import json
from datetime import datetime, timezone, timedelta
from selenium.webdriver import Chrome
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from dotenv import load_dotenv

load_dotenv(".lock_screen_cfg", override=True)

EMAIL = os.getenv("FHR_EMAIL")
PWD = os.getenv("FHR_PWD")
PROVIDER = os.getenv("FHR_PROVIDER")
FACTORIAL_SESSION = os.getenv("FACTORIAL_SESSION")
FACTORIAL_DATA = os.getenv("FACTORIAL_DATA")


def save(value, key):
    filename = ".lock_screen_cfg"
    if os.path.exists(filename):
        with open(filename, "r") as env_file:
            lines = env_file.readlines()

        updated_lines = []
        for line in lines:
            if line.startswith(f"{key}="):
                updated_lines.append(f"{key}=\"{value}\"\n")
            else:
                updated_lines.append(line)

        with open(filename, "w") as env_file:
            env_file.writelines(updated_lines)


def get_session():
    driver = Chrome()
    driver.get("https://api.factorialhr.com/en/users/sign_in?locale=en")
    time.sleep(5)
    if PROVIDER:
        google_login_button = driver.find_element(By.XPATH, f"//a[contains(@title, 'Continue with {PROVIDER}')]")
        google_login_button.click()
        time.sleep(5)
    email_input = driver.find_element(By.XPATH, "//input[@type='email']")
    email_input.send_keys(EMAIL)
    if PROVIDER:
        email_input.send_keys(Keys.ENTER)
    time.sleep(5)
    password_input = driver.find_element(By.XPATH, "//input[@type='password']")
    password_input.send_keys(PWD)
    password_input.send_keys(Keys.ENTER)
    if PROVIDER:
        time.sleep(30)
        try:
            tb = driver.find_element(By.CSS_SELECTOR, ".isClickable")
            while not tb:
                tb = driver.find_element(By.CSS_SELECTOR, ".isClickable")
                time.sleep(1)
                print("sleep 1")
            tb.click()
        except Exception as e:
            print(str(e))
    time.sleep(10)
    driver.get("https://api.factorialhr.com")
    cookies = driver.get_cookies()
    factorial_session_cookie = None
    for cookie in cookies:
        if cookie["name"] == "_factorial_session_v2":
            factorial_session_cookie = cookie
            break
    factorial_data_cookie = None
    for cookie in cookies:
        if cookie["name"] == "_factorial_data":
            factorial_data_cookie = cookie
            break
    print("Valor de la cookie de sesión:", factorial_session_cookie)
    print("Valor de la cookie de data:", factorial_data_cookie)
    return factorial_session_cookie["value"], factorial_data_cookie["value"]


def get_headers():
    return {
        'authority': 'api.factorialhr.com',
        'accept': 'application/json, text/plain, */*',
        'accept-language': 'en-GB,en-US;q=0.9,en;q=0.8',
        'content-type': 'application/json',
        'cookie': f'_factorial_session_v2={FACTORIAL_SESSION}',
        'origin': 'https://api.factorialhr.com',
        'referer': 'https://api.factorialhr.com/',
        'sec-ch-ua': '"Chromium";v="122", "Not(A:Brand";v="24", "Google Chrome";v="122"',
        'sec-ch-ua-mobile': '?0',
        'sec-ch-ua-platform': '"macOS"',
        'sec-fetch-dest': 'empty',
        'sec-fetch-mode': 'cors',
        'sec-fetch-site': 'same-site',
        'user-agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
        'x-factorial-access': '627783',
        'x-factorial-origin': 'web',
    }


def now():
    fecha_actual = datetime.now()
    fecha_actual_utc_mas_uno = fecha_actual.astimezone(timezone(timedelta(hours=2)))
    return fecha_actual_utc_mas_uno.strftime("%Y-%m-%dT%H:%M:%S%z")


def retry_on_fail(func):
    @wraps(func)
    def wrapper(*args, **kwargs):
        retries = 1
        while retries > 0:
            try:
                response = func(*args, **kwargs)
                if response.status_code == 401 or ("errors" in response.json() and response.status_code != 409):
                    # Si el código de estado es 401, intentamos obtener una nueva sesión y luego ejecutamos la función nuevamente
                    print("Attempting to get new session...")
                    FACTORIAL_SESSION, FACTORIAL_DATA = get_session()
                    save(FACTORIAL_SESSION, "FACTORIAL_SESSION")
                    save(FACTORIAL_DATA, "FACTORIAL_DATA")
                    response = func(*args, **kwargs)
                    if response.status_code >= 400:
                        return sys.exit(response.status_code)
                else:
                    # Si la llamada es exitosa y no hay errores, retornamos la respuesta
                    return response
            except requests.exceptions.RequestException as e:
                retries -= 1
                print(f"Error: {e}. Retrying...")
                time.sleep(5)  # Esperar un momento antes de volver a intentar
        print("Se agotaron los intentos.")
    return wrapper


@click.group()
def cli():
    pass


@cli.command()
@retry_on_fail
def clock_in():
    data = {"now": now(), "source": "desktop"}
    print("clock-in")
    print(json.dumps(data))
    response = requests.post('https://api.factorialhr.com/attendance/shifts/clock_in', headers=get_headers(), data=json.dumps(data))
    if response.status_code >= 400:
        print(response.status_code)
    return response


@cli.command()
@retry_on_fail
def clock_out():
    data = {"now": now(), "source": "desktop"}
    print("clock-out")
    print(json.dumps(data))
    response = requests.post('https://api.factorialhr.com/attendance/shifts/clock_out', headers=get_headers(), data=json.dumps(data))
    if response.status_code >= 400:
        print(response.status_code)
    return response


if __name__ == "__main__":
    cli()
