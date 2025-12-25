<%@ page 
    language="java" 
    contentType="text/html; charset=UTF-8" 
    pageEncoding="UTF-8"
%>
<%@ page import="java.math.BigInteger" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.HashMap" %>
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
        
        function exportDocument(textareaId) {
            const content = document.getElementById(textareaId).value;

            if (!content || content.trim() === "") {
                alert("Không có văn bản để xuất!");
                return;
            }

            const blob = new Blob([content], { type: 'text/plain;charset=utf-8' });
            const url = window.URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = 'document_signed.txt';
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
		
		        
		
		        <%-- Thông báo tạo khóa thành công --%>
		        <% if(session.getAttribute("msg_gen") != null) { %>
		            <div class="alert alert-success" style="margin-bottom: 12px;">
		                <%= session.getAttribute("msg_gen") %>
		            </div>
		        <% } %>
		
		        <form action="process" method="post" id="formGenerateKeys">
		            <input type="hidden" name="action" value="generateKeys">
		
		            <%-- p --%>
		            <label>p</label>
					<input type="text" name="p"
					 value="<%= request.getAttribute("input_p") != null
					     ? request.getAttribute("input_p")
					     : (session.getAttribute("key_p") != null
					         ? session.getAttribute("key_p")
					         : "") %>">
		
		            <%-- alpha --%>
		            <label>alpha</label>
					<input type="text" name="alpha"
					 value="<%= request.getAttribute("input_alpha") != null
					     ? request.getAttribute("input_alpha")
					     : (session.getAttribute("key_alpha") != null
					         ? session.getAttribute("key_alpha")
					         : "") %>">
		
		            <%-- x --%>
		            <label>x</label>
					<input type="text" name="x"
					 value="<%= request.getAttribute("input_x") != null
					     ? request.getAttribute("input_x")
					     : (session.getAttribute("key_x") != null
					         ? session.getAttribute("key_x")
					         : "") %>">
		
		            <div class="button-group">
		                <button type="submit" name="genMode" value="input" class="btn btn-primary">
		                    Tạo khóa từ đầu vào
		                </button>
		
		                <button type="button" onclick="resetKeys()" class="btn btn-danger btn-reset-key">
		                    Reset khóa
		                </button>
		            </div>
		
		            <div class="divider-text">hoặc</div>
		
		            <button type="submit" name="genMode" value="random" class="btn btn-success">
		                Tạo khóa ngẫu nhiên
		            </button>
		        </form>
		
		        <%-- Form reset khóa --%>
		        <form action="process" method="post" id="formResetKeys" style="display: none;">
		            <input type="hidden" name="action" value="resetKeys">
		        </form>
		
		        <%-- Hiển thị khóa đã sinh --%>
		        <div class="result-box">
		            <strong>Khóa Đã Sinh:</strong>
		
		            <% if(session.getAttribute("key_p") != null) { %>
		
		                <div class="key-row">
		                    <span class="key-label">Khóa bí mật:</span>
		                    <span class="key-value"><%= session.getAttribute("key_x") %></span>
		                </div>
		
		                <div class="key-row">
		                    <span class="key-label">Khóa công khai:</span>
		                    <span class="key-value"><%= session.getAttribute("key_y") %></span>
		                </div>
		
		            <% } else { %>
		                <div class="placeholder">
		                    Chưa có khóa. Hãy tạo khóa.
		                </div>
		            <% } %>
		        </div>
		
		    </div>
		</div>

		<!-- BƯỚC 2 -->
		<div class="card">
		    <div class="card-header">BƯỚC 2: KÝ TÀI LIỆU</div>
		    <div class="card-body">
		
		        <form action="process" method="post">
		            <!-- BẮT BUỘC: action ký -->
		            <input type="hidden" name="action" value="sign">
		
		            <label>Văn bản cần ký</label>
		            <textarea name="docContent" id="docContent"><%= docContentValue %></textarea>
		
		            <!-- Xuất văn bản -->
		            <button type="button"
		                    class="btn btn-export"
		                    style="margin-bottom: 10px;"
		                    onclick="exportDocument('docContent')">
		                Xuất văn bản đã ký
		            </button>
		
		            <!-- Chọn file -->
		            <input type="file" accept=".txt" onchange="readFile(this,'docContent')">
		
		            <!-- NÚT KÝ TÀI LIỆU -->
		            <button type="submit" class="btn btn-primary">
		                Ký tài liệu
		            </button>
		        </form>
		
		        <div class="result-box">
		            <strong>Chữ Ký Đã Sinh:</strong>
		            <% if(signR != null) { %>
		                <div class="key-row">
		                    <span class="key-label">r:</span>
		                    <span class="key-value"><%= signR %></span>
		                </div>
		                <div class="key-row">
		                    <span class="key-label">s:</span>
		                    <span class="key-value"><%= signS %></span>
		                </div>
		
		                <div class="signature-actions">
		                    <button type="button"
		                            class="btn-select"
		                            onclick="copySignature('<%= signR %>', '<%= signS %>')">
		                        Chọn
		                    </button>
		
		                    <button type="button"
		                            class="btn btn-export"
		                            onclick="exportSignature('<%= signR %>', '<%= signS %>')">
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
				    <% if (request.getAttribute("verify_checked") != null) {
				        String status = (String) request.getAttribute("verify_status");
				    %>
				
				        <% if ("OK".equals(status)) { %>
				            <div class="alert alert-success">
				                TRÙNG KHỚP
				            </div>
				
				        <% } else if ("SIG_MODIFIED".equals(status)) { %>
				            <div class="alert alert-danger">
				                CHỮ KÝ ĐÃ BỊ CHỈNH SỬA
				            </div>
				
				        <% } else if ("DOC_MODIFIED".equals(status)) { %>
				            <div class="alert alert-danger">
				                VĂN BẢN ĐÃ BỊ CHỈNH SỬA
				            </div>
						<% } else if ("BOTH_MODIFIED".equals(status)) { %>
						    <div class="alert alert-danger">
						        CHỮ KÝ VÀ VĂN BẢN ĐỀU ĐÃ BỊ CHỈNH SỬA
						    </div>
						<% } %>
				
				    <% } else { %>
				        <div class="placeholder">Chưa kiểm tra.</div>
				    <% } %>
				</div>
            </div>
        </div>

    </div>

    <div class="history-reset-card">
        <div class="history-section">
            <h3>Lịch sử hoạt động</h3>
            <div class="history-list">
                <%
                    ArrayList<Map<String, String>> history = (ArrayList<Map<String, String>>) session.getAttribute("history");
                    if (history == null || history.isEmpty()) {
                %>
                    <p class="placeholder">Chưa có hoạt động nào.</p>
                <%
                    } else {
                        for (int i = history.size() - 1; i >= 0; i--) {
                            Map<String, String> entry = history.get(i);
                %>
                            <div class="history-entry">
                                <span class="timestamp">[<%= entry.get("timestamp") %>]</span>
                                <span class="action"><%= entry.get("action") %></span>: 
                                <span class="data"><%= entry.get("data") %></span>
                            </div>
                <%
                        }
                    }
                %>
            </div>
        </div>

        <div class="reset-section">
            <form action="process" method="post" style="width:100%;">
                <input type="hidden" name="action" value="reset">
                <button type="submit" class="btn btn-danger reset-large">
                    Xóa toàn bộ dữ liệu
                </button>
            </form>
        </div>
    </div>

</div>

</body>
</html>