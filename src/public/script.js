document.addEventListener("htmx:afterRequest", function (event) {
    console.log(event.detail.xhr)
    let accessToken = event.detail.xhr.getResponseHeader("X-Access-Token");
    if (accessToken) {
        localStorage.setItem("access_token", accessToken);
    }
    let refreshToken = event.detail.xhr.getResponseHeader("X-Refresh-Token");
    if (refreshToken) {
        localStorage.setItem("refresh_token", refreshToken);
    }
    console.log({ accessToken, refreshToken })

});

