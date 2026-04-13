# A Dockerfile for running MicrogridUP.
FROM ubuntu:22.04
MAINTAINER <david.pinney@nreca.coop>

# Install OS prereqs.
RUN apt-get -y update && apt-get install -y python3 git sudo vim python3-pip python3-setuptools locales && rm -rf /var/lib/apt/lists/*

# Install the OMF
# Warning: clone might be cached. Consider invalidating manually.
RUN git clone --depth 1 https://github.com/nreca-bts/omf.git && cd omf && sudo python3 install.py && rm -rf /omf/.git
# Install a compatible version of numpy<2.0.0
RUN python3 -m pip install --no-cache-dir numpy==1.26.4 && rm -rf /root/.cache/pip /root/.cache/pip/http

# Force Julia install and reopt_jl setup.
RUN python3 -c "import omf; omf.solvers.reopt_jl.install_reopt_jl()" && rm -rf /julia-*.tar.gz /root/.cache/julia /tmp/* || true

# Move files across.
COPY . .

# Special requirements for graph layout (DEPRECATED)
# RUN sudo apt-get -y install graphviz graphviz-dev
# RUN pip install pygraphviz

# Also need a package for auth
RUN python3 -m pip install --no-cache-dir flask_httpauth && rm -rf /root/.cache/pip /root/.cache/pip/http

# Needed by microgridup_gui doc rendering import
RUN python3 -m pip install --no-cache-dir markdown && rm -rf /root/.cache/pip /root/.cache/pip/http

# Stupid workaround for an OpenDSS bug
RUN mkdir -p /root/Documents

# Set default locale = UTF-8
ENV PYTHONIOENCODING=UTF-8
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Run the MGU gui.
WORKDIR .
ENTRYPOINT ["python3"]
CMD ["microgridup_gui.py"]
EXPOSE 5000

# USAGE
# =====
# - Navigate to this directory
# - Build image with command `docker build . -f Dockerfile -t mguim`
# - Run image in background with `docker run -d -p 5000:5000 --name mgucont mguim`
# - View at http://127.0.0.1:5000
# - Stop it with `docker stop mgucont` and remove it with `docker rm mgucont`.
# - Delete the images with `docker rmi mguim`