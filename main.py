from fastapi import FastAPI
app=FastAPI()
@app.get('/api/health')
def h():return {'status':'ok'}
