export { Morris } from './morris.esm';

export interface ChartDonutData {
	label: string;
	value: number;
	ratio?: number;
}

export interface ChartData {
	[key: string]: unknown;
}

export interface ChartDonutOptions {
	element: string;
	data: ChartDonutData[];
	colors?: string[];
	formatter?: (y: number, data: ChartDonutData) => string;
	resize?: boolean;
	dataLabels?: boolean;
	dataLabelsPosition?: 'inside' | 'outside';
	donutType?: 'donut' | 'pie';
	animate?: boolean;
	showPercentage?: boolean;
	postUnits?: string;
	preUnits?: string;
}

interface GridOptions {
	element: string;
	data: ChartData[];
	ykeys: string[];
	labels: string[];
	hideHover?: boolean | 'auto' | 'always';
	axes?: boolean;
	grid?: boolean;
	gridTextColor?: string;
	gridTextSize?: number;
	gridTextFamily?: string;
	gridTextWeight?: string;
	resize?: boolean;
	fillOpacity?: number;
	dataLabels?: boolean;
	dataLabelsPosition?: 'inside' | 'outside' | 'force_outside';
	animate?: boolean;
	nbYkeys2?: number;
}

export interface ChartBarOptions extends GridOptions {
	xkey: string;
	barColors?: string[];
	stacked?: boolean;
	showZero?: boolean;
	hoverCallback?: (
		index: number,
		options: GridOptions,
		content: string,
		row: ChartData
	) => void;
}

export interface ChartLineOptions extends GridOptions {
	xkey: string | Date;
	lineColors?: string[];
	lineWidth?: number;
	pointSize?: number;
	pointFillColors?: string;
	pointStrokeColors?: string[];
	ymax?: string | number;
	ymin?: string | number;
	verticalGrid?: boolean;
	verticalGridType?: '' | '-' | '.' | '-.' | '-..' | '. ' | '- ' | '--' | '- .' | '--.' | '--..'
	smooth?: boolean;
	parseTime?: boolean;
	lineType?: 'smooth' | 'jagged' | 'step' | 'stepNoRiser' | 'vertical'
	trendLineType?: 'linear' | 'polynomial' | 'logarithmic' | 'exponential';
	trendLine?: boolean;
	postUnits?: string;
	preUnits?: string;
	dateFormat?: (timestamp: number) => string;
	xLabels?: string;
	xLabelFormat?: (date: Date) => string;
	xLabelAngle?: number;
	yLabelFormat?: (label: string | number) => string;
	goals?: string[];
	goalStrokeWidth?: number;
	goalLineColors?: string;
	events?: string[];
	eventStrokeWidth?: number;
	eventLineColors?: string[];
	continuousLine?: boolean;
}

export interface ChartAreaOptions extends ChartLineOptions {
	behaveLikeLine?: boolean;
}
