FROM ubuntu

WORKDIR /DIVYESH/APP

COPY . /DIVYESH/APP

RUN APT UPDATE && APT UPGRADE

EXPOSE 5678

CMD ["python" , "app.py"]