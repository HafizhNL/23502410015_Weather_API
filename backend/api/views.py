import requests
import os
from rest_framework.decorators import api_view
from rest_framework.response import Response

@api_view(['GET'])
def get_weather(request):
    city = request.GET.get('city', '').strip()
    
    if not city:
        return Response({'error': 'City is required'}, status=400)
    
    api_key = os.getenv('API_KEY')
    url = 'https://api.openweathermap.org/data/2.5/weather'
    params = {
        'q': city,
        'appid': api_key,
        'units': 'metric',
        'lang': 'en',
    }
    
    res = requests.get(url, params=params)
    
    if res.status_code == 200:
        return Response(res.json())
    elif res.status_code == 404:
        return Response({'error': 'City not found'}, status=404)
    elif res.status_code == 401:
        return Response({'error': 'Invalid API key'}, status=401)
    else:
        return Response({'error': f'Error {res.status_code}'}, status=res.status_code)
