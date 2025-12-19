<%@ page 
    language="java" 
    contentType="text/html; charset=UTF-8" 
    pageEncoding="UTF-8"
%>
<%@ page import="java.math.BigInteger" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Hệ thống Chữ ký số ElGamal</title>

    <link rel="stylesheet" href="css/style.css">

    <script>
        function readFile(input, targetId) {
            let file = input.files[0];
            if (!file) return;
            let reader = new FileReader();
            reader.onload = function() {
                document.getElementById(targetId).value = reader.result;
            };
            reader.readAsText(file);
        }
        
        function resetKeys() {
            document.getElementById('formResetKeys').submit();
        }

        function copySignature(r, s) {
            const signatureText = r + "," + s;
            navigator.clipboard.writeText(signatureText).then(function() {
                showCopyNotification("Đã copy chữ ký vào clipboard!");
            }, function(err) {
                alert("Lỗi khi copy: " + err);
            });
        }

        function showCopyNotification(message) {
            const notification = document.createElement('div');
            notification.className = 'copy-notification';
            notification.textContent = message;
            document.body.appendChild(notification);
            
            setTimeout(function() {
                notification.classList.add('show');
            }, 10);
            
            setTimeout(function() {
                notification.classList.remove('show');
                setTimeout(function() {
                    document.body.removeChild(notification);
                }, 300);
            }, 2000);
        }

        function exportSignature(r, s) {
            const signatureText = r + "," + s;
            const blob = new Blob([signatureText], { type: 'text/plain' });
            const url = window.URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = 'signature.txt';
            document.body.appendChild(a);
            a.click();
            document.body.removeChild(a);
            window.URL.revokeObjectURL(url);
        }
    </script>
</head>
<body>

<div class="container">
    <h1>Chữ Ký Số ElGamal</h1>
    <p class="subtitle">Thực hiện theo thứ tự từ Bước 1 → Bước 2 → Bước 3</p>

    <% if(request.getAttribute("error") != null) { %>
        <div class="alert alert-danger"><%= request.getAttribute("error") %></div>
    <% } %>

    <%
        String signR = (String) request.getAttribute("sign_r");
        String signS = (String) request.getAttribute("sign_s");
        String lastSignedDoc = (String) request.getAttribute("last_signed_doc");

        if (signR == null) signR = (String) session.getAttribute("sign_r_session");
        if (signS == null) signS = (String) session.getAttribute("sign_s_session");
        if (lastSignedDoc == null) lastSignedDoc = (String) session.getAttribute("last_signed_doc_session");

        String docContentValue = (String) request.getParameter("docContent");
        if (docContentValue == null) docContentValue = (lastSignedDoc != null ? lastSignedDoc : "");
    %>

    <div class="grid-container">

        <!-- BƯỚC 1 -->
        <div class="card">
            <div class="card-header">BƯỚC 1: TẠO KHÓA</div>
            <div class="card-body">
                <form action="process" method="post" id="formGenerateKeys">
                    <input type="hidden" name="action" value="generateKeys">

                    <label>p (số nguyên tố)</label>
                    <input type="text" name="p" value="${sessionScope.key_p != null ? sessionScope.key_p : ''}">

                    <label>alpha (căn nguyên)</label>
                    <input type="text" name="alpha" value="${sessionScope.key_alpha != null ? sessionScope.key_alpha : ''}">

                    <label>Khóa bí mật x</label>
                    <input type="text" name="x" value="${sessionScope.key_x != null ? sessionScope.key_x : ''}">

                    <div class="button-group">
                        <button type="submit" name="genMode" value="input" class="btn btn-primary">Tạo khóa từ đầu vào</button>
                        <button type="button" onclick="resetKeys()" class="btn btn-danger btn-reset-key">Reset khóa</button>
                    </div>

                    <div class="divider-text">hoặc</div>

                    <button type="submit" name="genMode" value="random" class="btn btn-success">Tạo khóa ngẫu nhiên</button>
                </form>
                
                <form action="process" method="post" id="formResetKeys" style="display: none;">
                    <input type="hidden" name="action" value="resetKeys">
                </form>

                <div class="result-box">
                    <strong>Khóa Đã Sinh:</strong>
                    <% if(session.getAttribute("key_p") != null) { %>

                        <div class="key-row">
                            <span class="key-label">x (khóa bí mật):</span>
                            <span class="key-value"><%= session.getAttribute("key_x") %></span>
                        </div>

                        <div class="key-row">
                            <span class="key-label">y (khóa công khai):</span>
                            <span class="key-value"><%= session.getAttribute("key_y") %></span>
                        </div>

                    <% } else { %>
                        <div class="placeholder">Chưa có khóa. Hãy tạo khóa.</div>
                    <% } %>
                </div>
            </div>
        </div>

        <!-- BƯỚC 2 -->
        <div class="card">
            <div class="card-header">BƯỚC 2: KÝ TÀI LIỆU</div>
            <div class="card-body">
                <form action="process" method="post">
                    <input type="hidden" name="action" value="sign">

                    <label>Văn bản cần ký</label>
                    <textarea name="docContent" id="docContent"><%= docContentValue %></textarea>

                    <input type="file" accept=".txt" onchange="readFile(this,'docContent')">

                    <button type="submit" class="btn btn-primary">Ký tài liệu</button>
                </form>

                <div class="result-box">
                    <strong>Chữ Ký Đã Sinh:</strong>
                    <% if(signR != null) { %>
                        <div class="key-row"><span class="key-label">r:</span> <span class="key-value"><%= signR %></span></div>
                        <div class="key-row"><span class="key-label">s:</span> <span class="key-value"><%= signS %></span></div>
                        
                        <div class="signature-actions">
                            <button type="button" class="btn-select" onclick="copySignature('<%= signR %>', '<%= signS %>')">
                                Chọn
                            </button>
                            <button type="button" class="btn-export" onclick="exportSignature('<%= signR %>', '<%= signS %>')">
                                Xuất file
                            </button>
                        </div>
                    <% } else { %>
                        <div class="placeholder">Chưa có chữ ký.</div>
                    <% } %>
                </div>
            </div>
        </div>

        <!-- BƯỚC 3 -->
        <div class="card">
            <div class="card-header">BƯỚC 3: XÁC MINH</div>
            <div class="card-body">
                <form action="process" method="post">
                    <input type="hidden" name="action" value="verify">

                    <label>Chữ ký (r,s)</label>
                    <textarea name="sigVerifyR" id="sigVerify"><%
                        if(request.getAttribute("verify_sig_input") != null) out.print(request.getAttribute("verify_sig_input"));
                        else if(signR != null) out.print(signR + "," + signS);
                    %></textarea>

                    <input type="file" accept=".txt" onchange="readFile(this,'sigVerify')">

                    <label>Văn bản gốc</label>
                    <textarea name="docVerify" id="docVerify"><%
                        if(request.getAttribute("verify_doc_input") != null) out.print(request.getAttribute("verify_doc_input"));
                        else if(lastSignedDoc != null) out.print(lastSignedDoc);
                    %></textarea>

                    <input type="file" accept=".txt" onchange="readFile(this,'docVerify')">

                    <button type="submit" class="btn btn-primary">Xác minh</button>
                </form>

                <div class="verify-result-section">
                    <% if(request.getAttribute("verify_checked") != null) {
                        boolean ok = (Boolean) request.getAttribute("verify_result");
                    %>
                        <div class="alert <%= ok ? "alert-success" : "alert-danger" %>">
                            <%= ok ? "CHỮ KÝ HỢP LỆ" : "CHỮ KÝ KHÔNG HỢP LỆ" %>
                        </div>
                    <% } else { %>
                        <div class="placeholder">Chưa kiểm tra.</div>
                    <% } %>
                </div>
            </div>
        </div>

    </div>

    <div class="reset-card">
        <form action="process" method="post">
            <input type="hidden" name="action" value="reset">
            <button class="btn btn-danger reset-small">Xóa toàn bộ dữ liệu</button>
        </form>
    </div>

</div>

</body>
</html>