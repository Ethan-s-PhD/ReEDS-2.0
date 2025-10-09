import json
import os
import requests
# Optional: load from .env if you prefer (pip install python-dotenv)
# from dotenv import load_dotenv; load_dotenv()

def to_slack(message, image=False):
    webhook_url = os.environ.get('SLACK_WEBHOOK_URL')
    if not webhook_url:
        raise RuntimeError('SLACK_WEBHOOK_URL is not set')

    slack_data = {'text': message}
    response = requests.post(
        webhook_url,
        data=json.dumps(slack_data),
        headers={'Content-Type': 'application/json'},
        timeout=10,
    )
    if response.status_code != 200:
        raise ValueError('Request to slack returned an error %s, the response is:\n%s' %
                         (response.status_code, response.text))
    return response

if __name__ == '__main__':
    print(to_slack('Test message from ReEDS-2.0 repo', image=False))