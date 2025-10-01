
// DialogDlg.h: 头文件
//

#pragma once
#include "CyAPI.h"

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
	afx_msg void OnBnClickedButtonDlNum18();
	afx_msg void OnBnClickedButtonDlNum36();
	afx_msg void OnBnClickedButtonContinuous();
	afx_msg void OnBnClickedButtonQuery();
private:
	bool SurveyExistingDevices();
	bool EnumerateEndpointForTheSelectedDevice();
	void ConfigADCSamplingRate();
	static DWORD WINAPI PerformADCSampling(LPVOID lParam);
	static DWORD WINAPI ConfigContinuousSampling(LPVOID lParam);
	void SwitchContinuousToQuery();
	CComboBox m_comboDevices;
	CCyUSBDevice* m_selectedUSBDevice;
	CButton m_buttonADCSample;
	CString m_strEndPointEnumerate0x02;
	CString m_strEndPointEnumerate0x86;
	CWinThread* m_pThread;
	bool m_bButtonADCSampleClicked;
	bool m_bButtonContinuousClicked;
	CEdit m_edtQuery;
	CButton m_buttonContinuous;
};
