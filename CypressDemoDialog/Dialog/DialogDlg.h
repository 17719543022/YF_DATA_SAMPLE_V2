
// DialogDlg.h: 头文件
//

#pragma once
#include "CyAPI.h"
#include "ChartCtrl/ChartCtrl.h"
#include "ChartCtrl/ChartAxisLabel.h"
#include "ChartCtrl/ChartLineSerie.h"

// CDialogDlg 对话框
class CDialogDlg : public CDialogEx
{
// 构造
public:
	CDialogDlg(CWnd* pParent = nullptr);	// 标准构造函数
	virtual ~CDialogDlg();

// 对话框数据
#ifdef AFX_DESIGN_TIME
	enum { IDD = IDD_DIALOG_DIALOG };
#endif

	protected:
	virtual void DoDataExchange(CDataExchange* pDX);	// DDX/DDV 支持


// 实现
protected:
	HICON m_hIcon;

	// 生成的消息映射函数
	virtual BOOL OnInitDialog();
	virtual LRESULT DefWindowProc(UINT message, WPARAM wParam, LPARAM lParam);

	afx_msg void OnSysCommand(UINT nID, LPARAM lParam);
	afx_msg void OnPaint();
	afx_msg HCURSOR OnQueryDragIcon();
	DECLARE_MESSAGE_MAP()
public:
	afx_msg void OnCbnSelchangeComboDevices();
	afx_msg void OnBnClickedButtonAdcSample();
	afx_msg void OnTimer(UINT_PTR nIDEvent);
private:
	bool SurveyExistingDevices();
	bool EnumerateEndpointForTheSelectedDevice();
	static DWORD WINAPI PerformADCSampling(LPVOID lParam);
	void DataBuffInit();
	void ChartCtrlInit();
	void LogScroll(CString log);
	CComboBox m_comboDevices;
	CCyUSBDevice* m_selectedUSBDevice;
	CButton m_buttonADCSample;
	CString m_strEndPointEnumerate0x02;
	CString m_strEndPointEnumerate0x86;
	CWinThread* m_pThread;
	bool m_bButtonADCSampleClicked;
	CChartCtrl m_ChartCtrl;
	CChartLineSerie* pLineSeries;
	CEdit m_edtDlNum;
	CEdit m_edtDebug;
};
