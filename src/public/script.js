function parseJwt(token) {
    var base64Url = token.split('.')[1];
    var base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/');
    var jsonPayload = decodeURIComponent(window.atob(base64).split('').map(function (c) {
        return '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2);
    }).join(''));

    return JSON.parse(jsonPayload);
}

document.addEventListener("htmx:afterRequest", function (event) {
    let accessToken = event.detail.xhr.getResponseHeader("X-Access-Token");
    if (accessToken) {
        localStorage.setItem("access_token", accessToken);
    }
    let refreshToken = event.detail.xhr.getResponseHeader("X-Refresh-Token");
    if (refreshToken) {
        localStorage.setItem("refresh_token", refreshToken);
    }

});

document.addEventListener("htmx:confirm", (e) => {
    const accessToken = localStorage.getItem("access_token");
    if (accessToken) {
        const payload = parseJwt(accessToken);
        const expiration = new Date(payload.exp)
        console.log(expiration)
    } else {
        console.log("nothing")
    }

})


document.addEventListener("htmx:configRequest", (e) => {
    const accessToken = localStorage.getItem("access_token");
    if (accessToken) {
        e.detail.headers["authorization"] = `Bearer ${accessToken}`;
    }
})