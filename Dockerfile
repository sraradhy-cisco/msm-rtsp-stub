####################################################################################################
## Builder
####################################################################################################
FROM rust:latest AS builder

RUN rustup target add x86_64-unknown-linux-musl
RUN apt update && apt install -y musl-tools musl-dev
RUN update-ca-certificates

# Create appuser
ENV USER=stub
ENV UID=10001

RUN adduser \
    --disabled-password \
    --gecos "" \
    --home "/nonexistent" \
    --shell "/sbin/nologin" \
    --no-create-home \
    --uid "${UID}" \
    "${USER}"

WORKDIR /msm-rtsp-stub

COPY ./ .

RUN cargo build --release 
RUN strip /msm-rtsp-stub/target/release/msm_rtsp_stub 

####################################################################################################
## Final image
####################################################################################################
FROM scratch

# Import from builder.
COPY --from=builder /etc/passwd /etc/passwd
COPY --from=builder /etc/group /etc/group

WORKDIR /msm-rtsp-stub

# Copy our build
COPY --from=builder /msm-rtsp-stub/target/release/msm_rtsp_stub ./

# Use an unprivileged user.
USER stub:stub 

CMD ["/msm-rtsp-stub/msm_rtsp_stub"]

